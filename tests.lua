-- tests.lua: Automated tests

-- Copyright 2023 Medallion Instrumentation Systems. All rights reserved.
--
-- THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

print 'Starting tests...'

require 'freeze'

-- Test that trying to create a global is an error.
local function create_global()
    x = 'hello'
end

local create_global_succeeded = pcall(create_global)

if create_global_succeeded then
    error "creating globals is permitted when it shouldn't be"
end

local calcvalue = require 'calcvalue'

local new_calcvalue = calcvalue.new_calcvalue
local const = calcvalue.const
local prelude = calcvalue.prelude

local context = require 'context'

local new_context = context.new_context

local function typecheck(value, ctx)
    local ctx = ctx or new_context()
    return value.type_in_context(ctx)
end

local function assert_eq(actual, expected)
    if actual ~= expected then
        local message = string.format('assertion error: found %s %s but expected %s %s',
            type(actual), actual, type(expected), expected)
        error(message, 2)
    end
end

-- test that Type : Type
assert_eq(typecheck(prelude.type), prelude.type)

-- test that Type prints as 'Type'
assert_eq(tostring(prelude.type), 'Type')

-- test that in context "a : Type", a : Type
local ctx = new_context()
ctx = ctx.push('a', prelude.type)
assert_eq(typecheck(const('a'), ctx), prelude.type)

-- test that in context "a : Type", it is false that a : a
assert_eq(typecheck(const('a'), ctx) == const('a'), false)

-- test that in context "a : Type, x : a", a : Type and x : a
ctx = ctx.push('x', const('a'))
assert_eq(typecheck(const('a'), ctx), prelude.type)
assert_eq(typecheck(const('x'), ctx), const('a'))

-- test that in context "a : Type, x : a", it is false that x : x
assert_eq(typecheck(const('x'), ctx) == const('x'), false)

-- test that in context "push : Type, x : push", x : push
ctx = new_context()
ctx = ctx.push('push', prelude.type)
ctx = ctx.push('x', const('push'))
assert_eq(typecheck(const('x'), ctx), const('push'))

-- test that a constant has no type if there's no context
assert_eq(typecheck(const('x')), nil)

-- test that the type of Type isn't a const called "Type"
assert_eq(typecheck(prelude.type) == const('Type'), false)

-- test that a const called "Type" isn't Type
assert_eq(const('Type') == prelude.type, false)

-- test that Type "equals" itself
assert_eq(prelude.type.equals(prelude.type), true)

-- test that contexts have lengths that update correctly
ctx = new_context()
assert_eq(#ctx, 0)
ctx = ctx.push('a', prelude.type)
assert_eq(#ctx, 1)
ctx = ctx.push('x', const('a'))
assert_eq(#ctx, 2)

-- test that contexts don't update in place
ctx = new_context()
ctx.push('a', prelude.type)
assert_eq(#ctx, 0)

print 'All tests passed.'