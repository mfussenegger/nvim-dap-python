local dappy = require("dap-python")

describe("test discovery", function()
  it("finds simple function", function()
    local source = [[
def test_foo():
    assert 1 == 2


class FooTest(TestCase):

    def test_bar(self):
        self.assertEqual(1, 2)


def last():
    assert 1 == 1
]]

    local nodes = dappy._get_nodes(source, "function", 7)
    assert.are.same(1, #nodes)
    assert.are.same("test_bar", vim.treesitter.get_node_text(nodes[1], source))

    nodes = dappy._get_nodes(source, "function", 4)
    assert.are.same(1, #nodes)
    assert.are.same("test_foo", vim.treesitter.get_node_text(nodes[1], source))
  end)

  it("ignores nested functions", function()
    local source = [[
class FooTest(TestCase):

    def test_foo(self):
        def dummy():
            return 1
        self.assertEqual(1, 2)
    ]]
    local nodes = dappy._get_nodes(source, "function", 5)
    assert.are.same(1, #nodes)
    assert.are.same("test_foo", vim.treesitter.get_node_text(nodes[1], source))
  end)

  it("finds class", function()
    local source = [[
class FooTest(TestCase):

    def test_foo(self):
        def dummy():
            return 1
        self.assertEqual(1, 2)
    ]]
    local nodes = dappy._get_nodes(source, "class", 5)
    assert.are.same(1, #nodes)
    assert.are.same("FooTest", vim.treesitter.get_node_text(nodes[1], source))
  end)
  it("returns all nested classes", function()
    local source = [[
class NoMatch(TestCase):
    def test_x(self):
        pass

class A(TestCase):

    class B(TestCase):

        def test_foo(self):
            def dummy():
                return 1
            self.assertEqual(1, 2)
        ]]
    local nodes = dappy._get_nodes(source, "class", 11)
    assert.are.same(2, #nodes)
    assert.are.same("A", vim.treesitter.get_node_text(nodes[1], source))
    assert.are.same("B", vim.treesitter.get_node_text(nodes[2], source))
  end)
end)
