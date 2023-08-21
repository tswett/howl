-- calcvalue.lua: Terms (values) in the calculus

-- Copyright 2023 Medallion Instrumentation Systems. All rights reserved.
--
-- THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

require 'freeze'

local module = {}

local calcvalue_metatable = {}

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

-- Create a calcvalue.
function module.new_calcvalue(name, metatype)
    if type(name) ~= 'string' then
        error('name must be a string', 2)
    end

    if type(metatype) ~= 'string' then
        error('metatype must be a string', 2)
    end

    local result = {is_calcvalue = true, name = name, metatype = metatype}

    setmetatable(result, calcvalue_metatable)

    return result
end

-- Create a calcvalue representing a variable.
--
-- TODO: this is misnamed.
function module.const(name)
    local this = module.new_calcvalue(name, 'var')

    function this.equals(other)
        return other.metatype == 'var' and this.name == other.name
    end

    function this.type_in_context(ctx)
        return ctx.items[name]
    end

    return this
end

local prelude = {}
module.prelude = prelude

prelude.type = module.new_calcvalue('Type', 'Type')

function prelude.type.equals(other)
    return other.metatype == 'Type'
end

function prelude.type.type_in_context(ctx)
    return prelude.type
end

-- Create a calcvalue representing a dependent product.
function module.forall(index, domain, codomain)
    local this = module.new_calcvalue('forall', 'forall')

    if not codomain.is_calcvalue then
        error('codomain must be a calcvalue', 2)
    end

    this.codomain = codomain

    function this.equals(other)
        return other.metatype == 'forall' and this.codomain == other.codomain
    end

    function this.type_in_context(ctx)
        return prelude.type
    end

    return this
end

-- Create a calcvalue representing a lambda binding.
function module.lambda(param, domain, body)
    local this = module.new_calcvalue('lambda', 'lambda')

    function this.type_in_context(ctx)
        local new_ctx = ctx.push(param, domain)

        local body_type = body.type_in_context(new_ctx)

        if type(body_type) ~= 'table' or not body_type.is_calcvalue then
            error "couldn't find a type for this body"
        end

        return module.forall(param, domain, body_type)
    end

    return this
end

return module
    