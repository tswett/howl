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
local var = calcvalue.var
local forall = calcvalue.forall
local lambda = calcvalue.lambda
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
assert_eq(typecheck(var('a'), ctx), prelude.type)

-- test that in context "a : Type", it is false that a : a
assert_eq(typecheck(var('a'), ctx) == var('a'), false)

-- test that in context "a : Type, x : a", a : Type and x : a
ctx = ctx.push('x', var('a'))
assert_eq(typecheck(var('a'), ctx), prelude.type)
assert_eq(typecheck(var('x'), ctx), var('a'))

-- test that in context "a : Type, x : a", it is false that x : x
assert_eq(typecheck(var('x'), ctx) == var('x'), false)

-- test that in context "push : Type, x : push", x : push
ctx = new_context()
ctx = ctx.push('push', prelude.type)
ctx = ctx.push('x', var('push'))
assert_eq(typecheck(var('x'), ctx), var('push'))

-- test that a varant has no type if there's no context
assert_eq(typecheck(var('x')), nil)

-- test that the type of Type isn't a var called "Type"
assert_eq(typecheck(prelude.type) == var('Type'), false)

-- test that a var called "Type" isn't Type
assert_eq(var('Type') == prelude.type, false)

-- test that Type "equals" itself
assert_eq(prelude.type.equals(prelude.type), true)

-- test that contexts have lengths that update correctly
ctx = new_context()
assert_eq(#ctx, 0)
ctx = ctx.push('a', prelude.type)
assert_eq(#ctx, 1)
ctx = ctx.push('x', var('a'))
assert_eq(#ctx, 2)

-- test that contexts don't update in place
ctx = new_context()
ctx.push('a', prelude.type)
assert_eq(#ctx, 0)

-- test that (forall (a : Type), Type) : Type
local forall_a_type = forall('a', prelude.type, prelude.type)
assert_eq(typecheck(forall_a_type), prelude.type)

-- test that (lambda (a : Type), a) : forall (a : Type, Type)
local lambda_a_a = lambda('a', prelude.type, var('a'))
assert_eq(typecheck(lambda_a_a), forall_a_type)

-- test that it is false that (lambda (a : Type), a) : forall (a : Type, a)
local forall_a_a = forall('a', prelude.type, var('a'))
assert_eq(typecheck(lambda_a_a) == forall_a_a, false)

-- test that (lambda (a : Type) (x : a), x) : forall (a : Type) (x : a), a
local lambda_a_x_x = lambda('a', prelude.type, lambda('x', var('a'), var('x')))
local forall_a_x_a = forall('a', prelude.type, forall('x', var('a'), var('a')))
local type_result = typecheck(lambda_a_x_x)
assert_eq(type_result, forall_a_x_a)

print 'All tests passed.'
