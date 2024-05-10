-- Token kinds
TK_PUNCT = "PUNCT" -- Punctuators
TK_NUM = "NUM"     -- Numeric literals
TK_EOF = "EOF"     -- End-of-file markers

-- Token type
Token = {}
Token.__index = Token

function Token.new(kind, loc, length, val)
  return setmetatable({
    kind = kind,
    loc = loc,
    length = length,
    val = val or nil
  }, Token)
end

-- Helper function to report an error
local function error_exit(fmt, ...)
  io.stderr:write(string.format(fmt, ...), "\n")
  os.exit(1)
end

-- Check if the token matches the specified string
local function equal(tok, str)
  return tok.loc == str
end

-- Skip the current token if it matches the string
local function skip(tok, str)
  if not equal(tok, str) then
    error_exit("expected '%s'", str)
  end
  return tok.next
end

-- Get the number from the token if it's a numeric token
local function get_number(tok)
  if tok.kind ~= TK_NUM then
    error_exit("expected a number")
  end
  return tonumber(tok.val)
end

-- Tokenize the input string
local function tokenize(input)
  local tokens = {}
  local index = 1
  local length = #input
  while index <= length do
    local char = string.sub(input, index, index)

    -- Skip whitespace
    if string.match(char, "%s") then
      index = index + 1

      -- Numeric literal
    elseif string.match(char, "%d") then
      local number = string.match(input, "%d+", index)
      index = index + #number
      table.insert(tokens, Token.new(TK_NUM, number, #number, number))

      -- Punctuator
    elseif char == "+" or char == "-" then
      table.insert(tokens, Token.new(TK_PUNCT, char, 1))
      index = index + 1
    else
      error_exit("invalid token")
    end
  end
  table.insert(tokens, Token.new(TK_EOF, "", 0))
  for i = 1, #tokens - 1 do
    tokens[i].next = tokens[i + 1]
  end
  return tokens[1]
end

-- Main function
local function main(arg)
  if #arg ~= 1 then
    error_exit("%s: invalid number of arguments", arg[0])
  end

  local tok = tokenize(arg[1])
  io.write("  .globl main\n")
  io.write("main:\n")

  -- First token must be a number
  io.write(string.format("  mov $%d, %%rax\n", get_number(tok)))
  tok = tok.next

  -- Handle + and - operators
  while tok.kind ~= TK_EOF do
    if equal(tok, "+") then
      io.write(string.format("  add $%d, %%rax\n", get_number(tok.next)))
      tok = tok.next.next
    else
      tok = skip(tok, "-")
      io.write(string.format("  sub $%d, %%rax\n", get_number(tok)))
      tok = tok.next
    end
  end

  io.write("  ret\n")
end

-- Execute with provided arguments
main(arg)
