-- This routine is called from the LDT environment to create the Moose.lua file stub for use in .miz files.

local MooseDynamicStatic = arg[1]
local MooseCommitHash = arg[2]
local MooseDevelopmentPath = arg[3]
local MooseSetupPath = arg[4]
local MooseTargetPath = arg[5]

print( "Moose (D)ynamic (S)tatic  : " .. MooseDynamicStatic )
print( "Commit Hash ID            : " .. MooseCommitHash )
print( "Moose development path    : " .. MooseDevelopmentPath )
print( "Moose setup path          : " .. MooseSetupPath )
print( "Moose target path         : " .. MooseTargetPath )

local MooseSourcesFilePath =  MooseSetupPath .. "/Moose.files"
local MooseFilePath = MooseTargetPath.."/Moose.lua"

print( "Reading Moose source list : " .. MooseSourcesFilePath )

local MooseFile = io.open( MooseFilePath, "w" )

if MooseDynamicStatic == "S" then
  MooseFile:write( "env.info( '*** MOOSE GITHUB Commit Hash ID: " .. MooseCommitHash .. " ***' )\n" )
end  

local MooseLoaderPath
if MooseDynamicStatic == "D" then
  MooseLoaderPath = MooseSetupPath .. "/Moose Templates/Moose_Dynamic_Loader.lua"
end
if MooseDynamicStatic == "S" then
  MooseLoaderPath = MooseSetupPath .. "/Moose Templates/Moose_Static_Loader.lua"
end

local MooseLoader = io.open( MooseLoaderPath, "r" )
local MooseLoaderText = MooseLoader:read( "*a" )
MooseLoader:close()

MooseFile:write( MooseLoaderText )


local MooseSourcesFile = io.open( MooseSourcesFilePath, "r" )
local MooseSource = MooseSourcesFile:read("*l")

while( MooseSource ) do
  
  if MooseSource ~= "" then
    local MooseFilePath = MooseDevelopmentPath .. "/" .. MooseSource
    if MooseDynamicStatic == "D" then
      print( "Load dynamic: " .. MooseSource )
      MooseFile:write( "__Moose.Include( '" .. MooseSource .. "' )\n" )
    end
    if MooseDynamicStatic == "S" then
      print( "Load static: " .. MooseSource )
      local MooseSourceFile = io.open( MooseFilePath, "r" )
      local MooseSourceFileText = MooseSourceFile:read( "*a" )
      MooseSourceFile:close()
      
      MooseFile:write( MooseSourceFileText )
    end
  end
  
  MooseSource = MooseSourcesFile:read("*l")
end

if MooseDynamicStatic == "D" then
  MooseFile:write( "BASE:TraceOnOff( true )\n" )
end
if MooseDynamicStatic == "S" then
  MooseFile:write( "BASE:TraceOnOff( false )\n" )
end

MooseFile:write( "env.info( '*** MOOSE INCLUDE END *** ' )\n" )

MooseSourcesFile:close()
MooseFile:close()
