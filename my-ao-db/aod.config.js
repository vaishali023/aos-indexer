import { defineConfig } from "ao-deploy";

export default defineConfig({
  "my-ao-db": {
    name: "my-ao-db",
    contractPath: "src/contract.lua",
    luaPath: "./src/?.lua",
    outDir: "./dist",
  },
});
