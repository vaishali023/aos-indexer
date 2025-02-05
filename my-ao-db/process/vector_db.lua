local sqlite = require("lsqlite3")
local json = require("json")
DBClient = DBClient or sqlite.open_memory()

-- Initialize schema and vector extension
local init_sql = [[
SELECT vec_version();

CREATE TABLE IF NOT EXISTS vectors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    embedding BLOB NOT NULL,  -- Vector data stored as BLOB
    metadata TEXT,            -- Optional metadata as JSON
    created_at INTEGER DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER DEFAULT (strftime('%s', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_vectors_created ON vectors(created_at);
]]

-- Vector database operations
local VectorDB = {}

-- Initialize database and load vector extension
function VectorDB.init()
    local result = DBClient:exec(init_sql)
    if not result then
        error("Failed to initialize vector database")
    end
    return { Status = "200", Data = "Vector database initialized" }
end

-- Insert a vector with optional metadata
function VectorDB.insert_vector(vector, metadata)
    if type(vector) ~= "table" then
        return { Status = "400", Error = "Vector must be a table" }
    end

    -- Convert vector to binary format for BLOB storage
    local vector_blob = json.encode(vector) -- TODO: Implement binary packing for better performance
    local metadata_json = metadata and json.encode(metadata) or nil

    local sql = [[
        INSERT INTO vectors (embedding, metadata, updated_at) 
        VALUES (?, ?, strftime('%s', 'now'))
    ]]

    local stmt = DBClient:prepare(sql)
    if not stmt then
        return { Status = "500", Error = "Failed to prepare insert statement" }
    end

    stmt:bind_values(vector_blob, metadata_json)
    local result = stmt:step()
    stmt:finalize()

    if result == sqlite.DONE then
        return { 
            Status = "200", 
            Data = { 
                id = DBClient:last_insert_rowid(),
                message = "Vector inserted successfully" 
            }
        }
    else
        return { Status = "500", Error = "Failed to insert vector" }
    end
end

-- Search for similar vectors using cosine similarity
function VectorDB.search_vectors(query_vector, limit, threshold)
    if type(query_vector) ~= "table" then
        return { Status = "400", Error = "Query vector must be a table" }
    end

    limit = limit or 10
    threshold = threshold or 0.8

    local query_blob = json.encode(query_vector)
    local sql = [[
        SELECT 
            id,
            metadata,
            vec_distance_cosine(embedding, ?) as similarity
        FROM vectors 
        WHERE vec_distance_cosine(embedding, ?) >= ?
        ORDER BY similarity DESC
        LIMIT ?
    ]]

    local stmt = DBClient:prepare(sql)
    if not stmt then
        return { Status = "500", Error = "Failed to prepare search statement" }
    end

    stmt:bind_values(query_blob, query_blob, threshold, limit)
    
    local results = {}
    while stmt:step() == sqlite.ROW do
        local metadata = stmt:get_value(1)
        if metadata then
            metadata = json.decode(metadata)
        end
        
        table.insert(results, {
            id = stmt:get_value(0),
            metadata = metadata,
            similarity = stmt:get_value(2)
        })
    end
    stmt:finalize()

    return {
        Status = "200",
        Data = results
    }
end

-- Delete a vector by ID
function VectorDB.delete_vector(id)
    if not id then
        return { Status = "400", Error = "ID is required" }
    end

    local sql = "DELETE FROM vectors WHERE id = ?"
    local stmt = DBClient:prepare(sql)
    if not stmt then
        return { Status = "500", Error = "Failed to prepare delete statement" }
    end

    stmt:bind_values(id)
    local result = stmt:step()
    stmt:finalize()

    if result == sqlite.DONE then
        return { Status = "200", Data = "Vector deleted successfully" }
    else
        return { Status = "500", Error = "Failed to delete vector" }
    end
end

-- Update vector metadata
function VectorDB.update_metadata(id, metadata)
    if not id then
        return { Status = "400", Error = "ID is required" }
    end
    if type(metadata) ~= "table" then
        return { Status = "400", Error = "Metadata must be a table" }
    end

    local metadata_json = json.encode(metadata)
    local sql = [[
        UPDATE vectors 
        SET metadata = ?, updated_at = strftime('%s', 'now')
        WHERE id = ?
    ]]

    local stmt = DBClient:prepare(sql)
    if not stmt then
        return { Status = "500", Error = "Failed to prepare update statement" }
    end

    stmt:bind_values(metadata_json, id)
    local result = stmt:step()
    stmt:finalize()

    if result == sqlite.DONE then
        return { Status = "200", Data = "Metadata updated successfully" }
    else
        return { Status = "500", Error = "Failed to update metadata" }
    end
end

-- Add handlers for vector database operations
Handlers.add("Init", "Init", function(msg)
    return VectorDB.init()
end)

Handlers.add("InsertVector", function(msg)
    return msg.Action == "InsertVector"
end, function(msg)
    return VectorDB.insert_vector(msg.Vector, msg.Metadata)
end)

Handlers.add("SearchVectors", function(msg)
    return msg.Action == "SearchVectors"
end, function(msg)
    return VectorDB.search_vectors(msg.Vector, msg.Limit, msg.Threshold)
end)

Handlers.add("DeleteVector", function(msg)
    return msg.Action == "DeleteVector"
end, function(msg)
    return VectorDB.delete_vector(msg.Id)
end)

Handlers.add("UpdateMetadata", function(msg)
    return msg.Action == "UpdateMetadata"
end, function(msg)
    return VectorDB.update_metadata(msg.Id, msg.Metadata)
end)

return VectorDB