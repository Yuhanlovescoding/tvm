import tvm
from tvm import relay

# 定义一个简单的 Relay 函数
x = relay.var("x", shape=(10, 10), dtype="float32")
y = relay.var("y", shape=(10, 10), dtype="float32")
z = relay.add(x, y)
func = relay.Function([x, y], z)

# 打印 Relay 函数
print(func)

