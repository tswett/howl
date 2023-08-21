-- context.lua: Contexts in the calculus

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

local context_mt = {}

function context_mt.__len(this)
    return this.count
end

function module.new_context()
    local this = {items = {}, count = 0}

    setmetatable(this, context_mt)

    function this.push(name, type)
        local new = module.new_context()

        for key, value in pairs(this.items) do
            new.items[key] = value
        end

        new.items[name] = type
        new.count = this.count + 1

        return new
    end

    return this
end

return module
