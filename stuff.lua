-- Copyright 2023 Medallion Instrumentation Systems. All rights reserved.
--
-- THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

calcvalue_metatable = {}

function calcvalue_metatable.__tostring(value)
    local name = value.name
    if type(name) == 'string' then
        return value.name
    else
        error("this value doesn't have a name assigned")
    end
end

function calcvalue_metatable.__eq(this, other)
    return this.equals(other)
end

function calcvalue_metatable.__index(this, key)
    local message = string.format("the key %s isn't present in this calcvalue", key)
    error(message, 2)
end

function new_calcvalue()
    local result = {}
    setmetatable(result, calcvalue_metatable)
    return result
end
    
prelude = {}

prelude.type = new_calcvalue()
prelude.type.name = 'Type'
prelude.type.metatype = 'Type'

function prelude.type.equals(other)
    return other.metatype == 'Type'
end

function prelude.type.type_in_context(ctx)
    return prelude.type
end

function const(name)
    local this = new_calcvalue()

    this.name = name
    this.metatype = 'const'

    function this.equals(other)
        return other.metatype == 'const' and this.name == other.name
    end

    function this.type_in_context(ctx)
        return ctx.items[name]
    end

    return this
end

function typecheck(value, ctx)
    local ctx = ctx or new_context()
    return value.type_in_context(ctx)
end

function new_context()
    local ctx = {items = {}}

    function ctx.push(name, type)
        ctx.items[name] = type
        return ctx
    end

    return ctx
end

function assert_eq(actual, expected)
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

-- test that in context "a : Type, x : a", x : a
ctx = ctx.push('x', const('a'))
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
