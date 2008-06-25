require "luaunit"
require "lfs"

-- Generate list of test cases from all Lua files in the t folder
-- whose names begin with Test. The module to require then looks like
-- "t.TestCaseName", which is found in t/TestCaseName.lua
for f in lfs.dir"t" do
    local case = f:match("^(Test.*).lua$") 
    if case then
	require("t."..case)
    end
end

-- use low verbosity to avoid cluttering the output of make
LuaUnit.result.verbosity = 0

-- run the tests to get a count of failures
failed = LuaUnit:run()

-- let make know if any failed by forcing lua.exe to exit with
-- failure status
if failed and failed > 0 then
    os.exit(1)
end
