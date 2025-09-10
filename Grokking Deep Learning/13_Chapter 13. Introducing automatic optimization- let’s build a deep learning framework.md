# Chapter 13. Introducing automatic optimization: let’s build a deep learning framework

### **In this chapter**

- What is a deep learning framework?
- Introduction to tensors
- Introduction to autograd
- How does addition backpropagation work?
- How to learn a framework
- Nonlinearity layers
- The embedding layer
- The cross-entropy layer
- The recurrent layer

“Whether we are based on carbon or on silicon makes no fundamental difference; we should each be treated with appropriate respect.”

*Arthur C. Clarke, *2010: Odyssey Two* (1982)*

### What is a deep learning framework?

#### Good tools reduce errors, speed development, and increase runtime performance

If you’ve been reading about deep learning for long, you’ve probably come across one of the major frameworks such as PyTorch, TensorFlow, Theano (recently deprecated), Keras, Lasagne, or DyNet. Framework development has been extremely rapid over the past few years, and, despite all frameworks being free, open source software, there’s a light spirit of competition and comradery around each framework.

Thus far, I’ve avoided the topic of frameworks because, first and foremost, it’s extremely important for you to know what’s going on under the hood of these frameworks by implementing algorithms yourself (from scratch in NumPy). But now we’re going to transition into using a framework, because the networks you’ll be training next—long short-term memory networks (LSTMs)—are very complex, and NumPy code describing their implementation is difficult to read, use, or debug (gradients are flying everywhere).

It’s exactly this code complexity that deep learning frameworks were created to mitigate. Especially if you wish to train a neural network on a GPU (giving 10–100× faster training), a deep learning framework can significantly reduce code complexity (reducing errors and increasing development speed) while also increasing runtime performance. For these reasons, their use is nearly universal within the research community, and a thorough understanding of a deep learning framework will be essential on your journey toward becoming a user or researcher of deep learning.

But we won’t jump into any deep learning frameworks you’ve heard of, because that would stifle your ability to learn about what complex models (such as LSTMs) are doing under the hood. Instead, you’ll build a light deep learning framework according to the latest trends in framework development. This way, you’ll have no doubt about what frameworks do when using them for complex architectures. Furthermore, building a small framework yourself should provide a smooth transition to using actual deep learning frameworks, because you’ll already be familiar with the API and the functionality underneath it. I found this exercise beneficial myself, and the lessons learned in building my own framework are especially useful when attempting to debug a troublesome model.

How does a framework simplify your code? Abstractly, it eliminates the need to write code that you’d repeat multiple times. Concretely, the most beneficial pieces of a deep learning framework are its support for automatic backpropagation and automatic optimization. These features let you specify only the forward propagation code of a model, with the framework taking care of backpropagation and weight updates automatically. Most frameworks even make the forward propagation code easier by providing high-level interfaces to common layers and loss functions.

### Introduction to tensors

#### Tensors are an abstract form of vectors and matrices

Up to this point, we’ve been working exclusively with vectors and matrices as the basic data structures for deep learning. Recall that a matrix is a list of vectors, and a vector is a list of scalars (single numbers). A *tensor* is the abstract version of this form of nested lists of numbers. A vector is a one-dimensional tensor. A matrix is a two-dimensional tensor, and higher dimensions are referred to as *n*-dimensional tensors. Thus, the beginning of a new deep learning framework is the construction of this basic type, which we’ll call `Tensor`:

```
123456789101112131415161718192021222324252627import numpy as np

class Tensor (object):

     def __init__(self, data):
         self.data = np.array(data)

     def __add__(self, other):
         return Tensor(self.data + other.data)

     def __repr__(self):
         return str(self.data.__repr__())

     def __str__(self):
         return str(self.data.__str__())

x = Tensor([1,2,3,4,5])
print(x)


    [1 2 3 4 5]

y = x + x
print(y)


    [ 2   4   6   8 10]
```

This is the first version of this basic data structure. Note that it stores all the numerical information in a NumPy array (`self.data`), and it supports one tensor operation (addition). Adding more operations is relatively simple: create more functions on the tensor class with the appropriate functionality.

### Introduction to automatic gradient computation (autograd)

#### Previously, you performed backpropagation by hand. Let’s make it automatic!

In [chapter 4](/book/grokking-deep-learning/chapter-4/ch04), you learned about derivatives. Since then, you’ve been computing derivatives by hand for each neural network you train. Recall that this is done by moving backward through the neural network: first compute the gradient at the output of the network, then use that result to compute the derivative at the next-to-last component, and so on until all weights in the architecture have correct gradients. This logic for computing gradients can also be added to the tensor object. Let me show you what I mean. New code is in **bold**:

```
123456789101112131415161718192021222324252627282930313233import numpy as np

class Tensor (object):

     def __init__(self, data, creators=None, creation_op=None):
         self.data = np.array(data)
         self.creation_op = creation_op
         self.creators = creators
         self.grad = None

     def backward(self, grad):
         self.grad = grad

         if(self.creation_op == "add"):
             self.creators[0].backward(grad)
             self.creators[1].backward(grad)

     def __add__(self, other):
         return Tensor(self.data + other.data,
                       creators=[self,other],
                       creation_op="add")

     def __repr__(self):
         return str(self.data.__repr__())

     def __str__(self):
         return str(self.data.__str__())

x = Tensor([1,2,3,4,5])
y = Tensor([2,2,2,2,2])

z = x + y
z.backward(Tensor(np.array([1,1,1,1,1])))
```

This method introduces two new concepts. First, each tensor gets two new attributes. `creators` is a list containing any tensors used in the creation of the current tensor (which defaults to `None`). Thus, when the two tensors `x` and `y` are added together, `z` has two `creators`, `x` and `y`. `creation_op` is a related feature that stores the instructions `creators` used in the creation process. Thus, performing `z` = `x` + `y` creates a *computation graph* with three nodes (`x`, `y`, and `z`) and two edges (`z` -> `x` and `z` -> `y`). Each edge is labeled by the `creation_op add`. This graph allows you to recursively backpropagate gradients.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0235-01.jpg)

The first new concept in this implementation is the automatic creation of this graph whenever you perform math operations. If you took `z` and performed further operations, the graph would continue with whatever resulting new variables pointed back to `z`.

The second new concept introduced in this version of `Tensor` is the ability to use this graph to compute gradients. When you call `z .backward()`, it sends the correct gradient for `x` and `y` given the function that was applied to create `z` (`add`). Looking at the graph, you place a vector of gradients (`np.array([1,1,1,1,1])`) on `z`, and then they’re applied to their parents. As you learned in [chapter 4](/book/grokking-deep-learning/chapter-4/ch04), backpropagating through addition means also applying addition when backpropagating. In this case, because there’s only one gradient to `add` into `x` or `y`, you copy the gradient from `z` onto `x` and `y`:

```
123456789print(x.grad)
print(y.grad)
print(z.creators)
print(z.creation_op)

[1 1 1 1 1]
[1 1 1 1 1]
[array([1, 2, 3, 4, 5]), array([2, 2, 2, 2, 2])]
add
```

Perhaps the most elegant part of this form of autograd is that it works recursively as well, because each vector calls `.backward()` on all of its `self.creators`:

| a = Tensor([1,2,3,4,5])<br>b = Tensor([2,2,2,2,2])<br>c = Tensor([5,4,3,2,1])<br>d = Tensor([-1,-2,-3,-4,-5])<br>e = a + b<br>f = c + d<br>g = e + f<br>g.backward(Tensor(np.array([1,1,1,1,1])))<br>print(a.grad) | **Output** **[1 1 1 1 1]** |
| --- | --- |

### A quick checkpoint

#### Everything in Tensor is another form of lessons already learned

Before moving on, I want to first acknowledge that even if it feels like a bit of a stretch or a heavy lift to think about gradients flowing over a graphical structure, this is nothing new compared to what you’ve already been working with. In the previous chapter on RNNs, you forward propagated in one direction and then back propagated across a (virtual graph) of activations.

You just didn’t explicitly encode the nodes and edges in a graphical data structure. Instead, you had a list of layers (dictionaries) and hand-coded the correct order of forward and backpropagation operations. Now you’re building a nice interface so you don’t have to write as much code. This interface lets you backpropagate recursively instead of having to handwrite complicated backprop code.

This chapter is only somewhat theoretical. It’s mostly about commonly used engineering practices for learning deep neural networks. In particular, this notion of a graph that gets built during forward propagation is called a *dynamic computation graph* because it’s built on the fly during forward prop. This is the type of autograd present in newer deep learning frameworks such as DyNet and PyTorch. Older frameworks such as Theano and TensorFlow have what’s called a *static computation graph*, which is specified before forward propagation even begins.

In general, dynamic computation graphs are easier to write/experiment with, and static computation graphs have faster runtimes because of some fancy logic under the hood. But note that dynamic and static frameworks have lately been moving toward the middle, allowing dynamic graphs to compile to static ones (for faster runtimes) or allowing static graphs to be built dynamically (for easier experimentation). In the long run, you’re likely to end up with both. The primary difference is whether forward propagation is happening during graph construction or after the graph is already defined. In this book, we’ll stick with dynamic.

The main point of this chapter is to help prepare you for deep learning in the real world, where 10% (or less) of your time will be spent thinking up a new idea and 90% of your time will be spent figuring out how to get a deep learning framework to play nicely. Debugging these frameworks can be extremely difficult at times, because most bugs don’t raise an error and print out a stack trace. Most bugs lie hidden within the code, keeping the network from training as it should (even if it appears to be training somewhat).

All that is to say, really dive into this chapter. You’ll be glad you did when it’s 2:00 a.m. and you’re chasing down an optimization bug that’s keeping you from getting that juicy state-of-the-art score.

### Tensors that are used multiple times

#### The basic autograd has a rather pesky bug. Let’s squish it!

The current version of `Tensor` supports backpropagating into a variable only once. But sometimes, during forward propagation, you’ll use the same tensor multiple times (the weights of a neural network), and thus multiple parts of the graph will backpropagate gradients into the same tensor. But the code will currently compute the incorrect gradient when backpropagating into a variable that was used multiple times (is the parent of multiple children). Here’s what I mean:

```
12345678910111213a = Tensor([1,2,3,4,5])
b = Tensor([2,2,2,2,2])
c = Tensor([5,4,3,2,1])

d = a + b
e = b + c
f = d + e
f.backward(Tensor(np.array([1,1,1,1,1])))

print(b.grad.data == np.array([2,2,2,2,2]))


array([False, False, False, False, False])
```

In this example, the `b` variable is used twice in the process of creating `f`. Thus, its gradient should be the sum of two derivatives: `[2,2,2,2,2]`. Shown here is the resulting graph created by this chain of operations. Notice there are now two pointers pointing into `b`: so, it should be the sum of the gradient coming from both `e` and `d`.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0237-01.jpg)

But the current implementation of `Tensor` merely overwrites each derivative with the previous. First, `d` applies its gradient, and then it gets overwritten with the gradient from `e`. We need to change the way gradients are written.

### Upgrading autograd to support multiuse tensors

#### Add one new function, and update three old ones

This update to the `Tensor` object adds two new features. First, gradients can be accumulated so that when a variable is used more than once, it receives gradients from all children:

```
12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364656667686970717273747576777879import numpy as np
class Tensor (object):

    def __init__(self,data,
                 autograd=False,
                 creators=None,
                 creation_op=None,
                 id=None):

        self.data = np.array(data)
        self.creators = creators
        self.creation_op = creation_op
        self.grad = None
        self.autograd = autograd
        self.children = {}
        if(id is None):
            id = np.random.randint(0,100000)
        self.id = id

        if(creators is not None):
            for c in creators:
                if(self.id not in c.children):
                    c.children[self.id] = 1
                else:
                    c.children[self.id] += 1

    def all_children_grads_accounted_for(self):
        for id,cnt in self.children.items():
            if(cnt != 0):
                return False
        return True

    def backward(self,grad=None, grad_origin=None):
        if(self.autograd):
            if(grad_origin is not None):
                if(self.children[grad_origin.id] == 0):
                    raise Exception("cannot backprop more than once")
                else:
                    self.children[grad_origin.id] -= 1

            if(self.grad is None):
                self.grad = grad
            else:
                self.grad += grad

            if(self.creators is not None and
               (self.all_children_grads_accounted_for() or
                grad_origin is None)):

                if(self.creation_op == "add"):
                    self.creators[0].backward(self.grad, self)
                    self.creators[1].backward(self.grad, self)

    def __add__(self, other):
        if(self.autograd and other.autograd):
            return Tensor(self.data + other.data,
                          autograd=True,
                          creators=[self,other],
                          creation_op="add")
        return Tensor(self.data + other.data)

    def __repr__(self):
        return str(self.data.__repr__())

    def __str__(self):
        return str(self.data.__str__())

a = Tensor([1,2,3,4,5], autograd=True)
b = Tensor([2,2,2,2,2], autograd=True)
c = Tensor([5,4,3,2,1], autograd=True)

d = a + b
e = b + c
f = d + e

f.backward(Tensor(np.array([1,1,1,1,1])))

print(b.grad.data == np.array([2,2,2,2,2]))
```

```
[ True  True  True  True  True]
```

Additionally, you create a `self.children` counter that counts the number of gradients received from each child during backpropagation. This way, you also prevent a variable from accidentally backpropagating from the same child twice (which throws an exception).

The second added feature is a new function with the rather verbose name `all_children_grads_accounted_for()`. The purpose of this function is to compute whether a tensor has received gradients from all of its children in the graph. Normally, whenever `.backward()` is called on an intermediate variable in a graph, it immediately calls `.backward()` on its parents. But because some variables receive their gradient value from multiple parents, each variable needs to wait to call `.backward()` on its parents until it has the final gradient locally.

As mentioned previously, none of these concepts are new from a deep learning theory perspective; these are the kinds of engineering challenges that deep learning frameworks seek to face. More important, they’re the kinds of challenges you’ll face when debugging neural networks in a standard framework. Before moving on, take a moment to play around and get familiar with this code. Try deleting different parts and seeing how it breaks in various ways. Try calling `.backprop()` twice.

### How does addition backpropagation work?

#### Let’s study the abstraction to learn how to add support for more functions

At this point, the framework has reached an exciting place! You can now add support for arbitrary operations by adding the function to the `Tensor` class and adding its derivative to the `.backward()` method. For addition, there’s the following method:

```
1234567def __add__(self, other):
    if(self.autograd and other.autograd):
        return Tensor(self.data + other.data,
                      autograd=True,
                      creators=[self,other],
                      creation_op="add")
    return Tensor(self.data + other.data)
```

And for backpropagation through the addition function, there’s the following gradient propagation within the `.backward()` method:

```
123           if(self.creation_op == "add"):
             self.creators[0].backward(self.grad, self)
             self.creators[1].backward(self.grad, self)
```

Notice that addition isn’t handled anywhere else in the class. The generic backpropagation logic is abstracted away so everything necessary for addition is defined in these two places. Note further that backpropagation logic calls `.backward()` two times, once for each variable that participated in the addition. Thus, the default setting in the backpropagation logic is to always backpropagate into every variable in the graph. But occasionally, backpropagation is skipped if the variable has autograd turned off (`self.autograd` == `False`). This check is performed in the `.backward()` method:

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0240-01_alt.jpg)

Even though the backpropagation logic for addition backpropagates the gradient into all the variables that contributed to it, the backpropagation won’t run unless `.autograd` is set to `True` for that variable (for `self.creators[0]` or `self.creators[1]`, respectively). Also notice in the first line of `__add__()` that the tensor created (which is later the tensor `running.backward()`) has `self.autograd` == `True` only if `self.autograd` == `other.autograd` == `True`.

### Adding support for negation

#### Let’s modify the support for addition to support negation

Now that addition is working, you should be able to copy and paste the addition code, create a few modifications, and add autograd support for negation. Let’s try it. Modifications from the `__add__` function are in bold:

```
1234567def __neg__(self):
    if(self.autograd):
        return Tensor(self.data * -1,
                      autograd=True,
                      creators=[self],
                      creation_op="neg")
    return Tensor(self.data * -1)
```

Nearly everything is identical. You don’t accept any parameters so the parameter “other” has been removed in several places. Let’s take a look at the backprop logic you should add to `.backward()`. Modifications from the `__add__` function backpropagation logic are in bold:

```
12if(self.creation_op == "neg"):
               self.creators[0].backward(self.grad.__neg__())
```

Because the `__neg__` function has only one creator, you end up calling `.backward()` only once. (If you’re wondering how you know the correct gradients to backpropagate, revisit [chapters 4](/book/grokking-deep-learning/chapter-4/ch04), [5](/book/grokking-deep-learning/chapter-5/ch05), and [6](/book/grokking-deep-learning/chapter-6/ch06).) You can now test out the new code:

```
1234567891011121314a = Tensor([1,2,3,4,5], autograd=True)
b = Tensor([2,2,2,2,2], autograd=True)
c = Tensor([5,4,3,2,1], autograd=True)

d = a + (-b)
e = (-b) + c
f = d + e

f.backward(Tensor(np.array([1,1,1,1,1])))

print(b.grad.data == np.array([-2,-2,-2,-2,-2]))


[ True  True  True  True  True]
```

When you forward propagate using `-b` instead of `b`, the gradients that are backpropagated have a flipped sign as well. Furthermore, you don’t have to change anything about the general backpropagation system to make this work. You can create new functions as you need them. Let’s add some more!

### Adding support for additional functions

#### Subtraction, multiplication, sum, expand, transpose, and matrix multiplication

Using the same ideas you learned for addition and negation, let’s add the forward and backpropagation logic for several additional functions:

```
123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354def __sub__(self, other):
     if(self.autograd and other.autograd):
         return Tensor(self.data - other.data,
                       autograd=True,
                       creators=[self,other],
                       creation_op="sub")
     return Tensor(self.data - other.data)

 def __mul__(self, other):
     if(self.autograd and other.autograd):
         return Tensor(self.data * other.data,
                       autograd=True,
                       creators=[self,other],
                       creation_op="mul")
     return Tensor(self.data * other.data)

 def sum(self, dim):
     if(self.autograd):
         return Tensor(self.data.sum(dim),
                        autograd=True,
                        creators=[self],
                        creation_op="sum_"+str(dim))
     return Tensor(self.data.sum(dim))

 def expand(self, dim,copies):

     trans_cmd = list(range(0,len(self.data.shape)))
     trans_cmd.insert(dim,len(self.data.shape))
     new_shape = list(self.data.shape) + [copies]
     new_data = self.data.repeat(copies).reshape(new_shape)
     new_data = new_data.transpose(trans_cmd)

     if(self.autograd):
         return Tensor(new_data,
                       autograd=True,
                       creators=[self],
                       creation_op="expand_"+str(dim))
     return Tensor(new_data)

 def transpose(self):
     if(self.autograd):
         return Tensor(self.data.transpose(),
                       autograd=True,
                       creators=[self],
                       creation_op="transpose")
     return Tensor(self.data.transpose())

 def mm(self, x):
     if(self.autograd):
         return Tensor(self.data.dot(x.data),
                       autograd=True,
                       creators=[self,x],
                       creation_op="mm")
     return Tensor(self.data.dot(x.data))
```

We’ve previously discussed the derivatives for all these functions, although `sum` and `expand` might seem foreign because they have new names. `sum` performs addition across a dimension of the tensor; in other words, say you have a 2 × 3 matrix called `x`:

```
12            x = Tensor(np.array([[1,2,3],
                                [4,5,6]]))
```

The `.sum(dim)` function sums across a dimension. `x.sum(0)` will result in a 1 × 3 matrix (a length 3 vector), whereas `x.sum(1)` will result in a 2 × 1 matrix (a length 2 vector):

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0243-00_alt.jpg)

You use `expand` to backpropagate through a `.sum()`. It’s a function that copies data along a dimension. Given the same matrix `x`, copying along the first dimension gives two copies of the tensor:

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0243-01_alt.jpg)

To be clear, whereas `.sum()` removes a dimension (2 × 3 -> just 2 or 3), `expand` adds a dimension. The 2 × 3 matrix becomes 4 × 2 × 3. You can think of this as a list of four tensors, each of which is 2 × 3. But if you expand to the last dimension, it copies along the last dimension, so each entry in the original tensor becomes a list of entries instead:

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0243-02_alt.jpg)

Thus, when you perform `.sum(dim=1)` on a tensor with four entries in that dimension, you need to perform `.expand(dim=1, copies=4)` to the gradient when you backpropagate it.

You can now add the corresponding backpropagation logic to the `.backward()` method:

```
1234567891011121314151617181920212223242526272829303132if(self.creation_op == "sub"):
              new = Tensor(self.grad.data)
              self.creators[0].backward(new, self)
              new = Tensor(self.grad.__neg__().data)
              self.creators[1].backward(, self)

          if(self.creation_op == "mul"):
              new = self.grad * self.creators[1]
              self.creators[0].backward(new , self)
              new = self.grad * self.creators[0]
              self.creators[1].backward(new, self)

          if(self.creation_op == "mm"):
              act = self.creators[0]
              weights = self.creators[1]
              new = self.grad.mm(weights.transpose())
              act.backward(new)
              new = self.grad.transpose().mm(act).transpose()
              weights.backward(new)

          if(self.creation_op == "transpose"):
              self.creators[0].backward(self.grad.transpose())

          if("sum" in self.creation_op):
              dim = int(self.creation_op.split("_")[1])
              ds = self.creators[0].data.shape[dim]
              self.creators[0].backward(self.grad.expand(dim,ds))

          if("expand" in self.creation_op):
              dim = int(self.creation_op.split("_")[1])
              self.creators[0].backward(self.grad.sum(dim))
```

If you’re unsure about this functionality, the best thing to do is to look back at how you were doing backpropagation in [chapter 6](/book/grokking-deep-learning/chapter-6/ch06). That chapter has figures showing each step of backpropagation, part of which I’ve shown again here.

The gradients start at the end of the network. You then move the error signal *backward through the network* by calling functions that correspond to the functions used to move activations *forward through the network*. If the last operation was a matrix multiplication (and it was), you backpropagate by performing matrix multiplication (dot) on the transposed matrix.

In the following image, this happens at the line `layer_1_delta=layer_2_delta.dot (weights_1_2.T)`. In the previous code, it happens in `if(self.creation_op == "mm")` (highlighted in bold). You’re doing the exact same operations as before (in reverse order of forward propagation), but the code is better organized.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0245-01_alt.jpg)

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0245-02_alt.jpg)

### Using autograd to train a neural network

#### You no longer have to write backpropagation logic!

This may have seemed like quite a bit of engineering effort, but it’s about to pay off. Now, when you train a neural network, you don’t have to write any backpropagation logic! As a toy example, here’s a neural network to backprop by hand:

```
12345678910111213141516171819202122232425import numpy
np.random.seed(0)

data = np.array([[0,0],[0,1],[1,0],[1,1]])
target = np.array([[0],[1],[0],[1]])

weights_0_1 = np.random.rand(2,3)
weights_1_2 = np.random.rand(3,1)

for i in range(10):

    layer_1 = data.dot(weights_0_1)
    layer_2 = layer_1.dot(weights_1_2)

    diff = (layer_2 - target)
    sqdiff = (diff * diff)
    loss = sqdiff.sum(0)
    layer_1_grad = diff.dot(weights_1_2.transpose())
    weight_1_2_update = layer_1.transpose().dot(diff)
    weight_0_1_update = data.transpose().dot(layer_1_grad)

    weights_1_2 -= weight_1_2_update * 0.1
    weights_0_1 -= weight_0_1_update * 0.1
    print(loss[0])
```

```
123456789100.4520108746468352
0.33267400101121475
0.25307308516725036
0.1969566997160743
0.15559900212801492
0.12410658864910949
0.09958132129923322
0.08019781265417164
0.06473333002675746
0.05232281719234398
```

You have to forward propagate in such a way that `layer_1`, `layer_2`, and `diff` exist as variables, because you need them later. You then have to backpropagate each gradient to its appropriate weight matrix and perform the weight update appropriately.

```
123456789101112131415161718192021222324import numpy
np.random.seed(0)

data = Tensor(np.array([[0,0],[0,1],[1,0],[1,1]]), autograd=True)
target = Tensor(np.array([[0],[1],[0],[1]]), autograd=True)

w = list()
w.append(Tensor(np.random.rand(2,3), autograd=True))
w.append(Tensor(np.random.rand(3,1), autograd=True))

for i in range(10):

     pred = data.mm(w[0]).mm(w[1])

     loss = ((pred - target)*(pred - target)).sum(0)

     loss.backward(Tensor(np.ones_like(loss.data)))

     for w_ in w:
         w_.data -= w_.grad.data * 0.1
         w_.grad.data *= 0

     print(loss)
```

But with the fancy new autograd system, the code is much simpler. You don’t have to keep around any temporary variables (because the dynamic graph keeps track of them), and you don’t have to implement any backpropagation logic (because the `.backward()` method handles that). Not only is this more convenient, but you’re less likely to make silly mistakes in the backpropagation code, reducing the likelihood of bugs!

```
12345678910[0.58128304]
[0.48988149]
[0.41375111]
[0.34489412]
[0.28210124]
[0.2254484]
[0.17538853]
[0.1324231]
[0.09682769]
[0.06849361]
```

Before moving on, I’d like to point out one stylistic thing in this new implementation. Notice that I put all the parameters in a list, which I could iterate through when performing the weight update. This is a bit of foreshadowing for the next piece of functionality. When you have an autograd system, stochastic gradient descent becomes trivial to implement (it’s just that `for` loop at the end). Let’s try making this its own class as well.

### Adding automatic optimization

#### Let’s make a stochastic gradient descent optimizer

At face value, creating something called a stochastic gradient descent optimizer may sound difficult, but it’s just copying and pasting from the previous example with a bit of good, old-fashioned object-oriented programming:

```
123456789101112131415161718class SGD(object):

    def __init__(self, parameters, alpha=0.1):
        self.parameters = parameters
        self.alpha = alpha

    def zero(self):
        for p in self.parameters:
            p.grad.data *= 0

    def step(self, zero=True):

        for p in self.parameters:

            p.data -= p.grad.data * self.alpha

            if(zero):
               p.grad.data *= 0
```

The previous neural network is further simplified as follows, with exactly the same results as before:

```
123456789101112131415161718192021import numpy
np.random.seed(0)

data = Tensor(np.array([[0,0],[0,1],[1,0],[1,1]]), autograd=True)
target = Tensor(np.array([[0],[1],[0],[1]]), autograd=True)

w = list()
w.append(Tensor(np.random.rand(2,3), autograd=True))
w.append(Tensor(np.random.rand(3,1), autograd=True))

optim = SGD(parameters=w, alpha=0.1)

for i in range(10):

    pred = data.mm(w[0]).mm(w[1])

    loss = ((pred - target)*(pred - target)).sum(0)

    loss.backward(Tensor(np.ones_like(loss.data)))
    optim.step()
```

### Adding support for layer types

#### You may be familiar with layer types in Keras or PyTorch

At this point, you’ve done the most complicated pieces of the new deep learning framework. Further work is mostly about adding new functions to the tensor and creating convenient higher-order classes and functions. Probably the most common abstraction among nearly all frameworks is the layer abstraction. It’s a collection of commonly used forward propagation techniques packaged into an simple API with some kind of `.forward()` method to call them. Here’s an example of a simple linear layer:

```
12345678910111213141516171819202122class Layer(object):

    def __init__(self):
        self.parameters = list()

    def get_parameters(self):
        return self.parameters


class Linear(Layer):

    def __init__(self, n_inputs, n_outputs):
        super().__init__()
        W = np.random.randn(n_inputs, n_outputs)*np.sqrt(2.0/(n_inputs))
        self.weight = Tensor(W, autograd=True)
        self.bias = Tensor(np.zeros(n_outputs), autograd=True)

        self.parameters.append(self.weight)
        self.parameters.append(self.bias)

    def forward(self, input):
        return input.mm(self.weight)+self.bias.expand(0,len(input.data))
```

Nothing here is particularly new. The weights are organized into a class (and I added bias weights because this is a true linear layer). You can initialize the layer all together, such that both the weights and bias are initialized with the correct sizes, and the correct forward propagation logic is always employed.

Also notice that I created an abstract class `Layer`, which has a single getter. This allows for more-complicated layer types (such as layers containing other layers). All you need to do is override `get_parameters()` to control what tensors are later passed to the optimizer (such as the `SGD` class created in the previous section).

### Layers that contain layers

#### Layers can also contain other layers

The most popular layer is a sequential layer that forward propagates a list of layers, where each layer feeds its outputs into the inputs of the next layer:

```
1234567891011121314151617181920212223242526272829303132333435363738class Sequential(Layer):

    def __init__(self, layers=list()):
        super().__init__()

        self.layers = layers

    def add(self, layer):
        self.layers.append(layer)

    def forward(self, input):
        for layer in self.layers:
            input = layer.forward(input)
        return input

    def get_parameters(self):
        params = list()
        for l in self.layers:
            params += l.get_parameters()
        return params

data = Tensor(np.array([[0,0],[0,1],[1,0],[1,1]]), autograd=True)
target = Tensor(np.array([[0],[1],[0],[1]]), autograd=True)

model = Sequential([Linear(2,3), Linear(3,1)])

optim = SGD(parameters=model.get_parameters(), alpha=0.05)

for i in range(10):

    pred = model.forward(data)

    loss = ((pred - target)*(pred - target)).sum(0)

    loss.backward(Tensor(np.ones_like(loss.data)))
    optim.step()
    print(loss)
```

### Loss-function layers

#### Some layers have no weights

You can also create layers that are functions on the input. The most popular version of this kind of layer is probably the loss-function layer, such as mean squared error:

```
1234567891011121314151617181920212223242526272829class MSELoss(Layer):

    def __init__(self):
        super().__init__()

    def forward(self, pred, target):
        return ((pred - target)*(pred - target)).sum(0)

import numpy
np.random.seed(0)

data = Tensor(np.array([[0,0],[0,1],[1,0],[1,1]]), autograd=True)
target = Tensor(np.array([[0],[1],[0],[1]]), autograd=True)

model = Sequential([Linear(2,3), Linear(3,1)])
criterion = MSELoss()

optim = SGD(parameters=model.get_parameters(), alpha=0.05)

for i in range(10):

    pred = model.forward(data)

    loss = criterion.forward(pred, target)

    loss.backward(Tensor(np.ones_like(loss.data)))
    optim.step()
    print(loss)
```

```
12345[2.33428272]
                     [0.06743796]
                         ...
                     [0.01153118]
                     [0.00889602]
```

If you’ll forgive the repetition, again, nothing here is particularly new. Under the hood, the last several code examples all do the exact same computation. It’s just that autograd is doing all the backpropagation, and the forward propagation steps are packaged in nice classes to ensure that the functionality executes in the correct order.

### How to learn a framework

#### Oversimplified, frameworks are autograd + a list of prebuilt laye- ers and optimizers

You’ve been able to write (rather quickly) a variety of new layer types using the underlying autograd system, which makes it quite easy to piece together arbitrary layers of functionality. Truth be told, this is the main feature of modern frameworks, eliminating the need to handwrite each and every math operation for forward and backward propagation. Using frameworks greatly increases the speed with which you can go from idea to experiment and will reduce the number of bugs in your code.

Viewing a framework as merely an autograd system coupled with a big list of layers and optimizers will help you learn them. I expect you’ll be able to pivot from this chapter into almost any framework fairly quickly, although the framework that’s most similar to the API built here is PyTorch. Either way, for your reference, take a moment to peruse the lists of layers and optimizers in several of the big frameworks:

- [https://pytorch.org/docs/stable/nn.html](https://pytorch.org/docs/stable/nn.html)
- [https://keras.io/layers/about-keras-layers](https://keras.io/layers/about-keras-layers)
- [https://www.tensorflow.org/api_docs/python/tf/layers](https://www.tensorflow.org/api_docs/python/tf/layers)

The general workflow for learning a new framework is to find the simplest possible code example, tweak it and get to know the autograd system’s API, and then modify the code example piece by piece until you get to whatever experiment you care about.

```
12345def backward(self,grad=None, grad_origin=None):
    if(self.autograd):

        if(grad is None):
            grad = Tensor(np.ones_like(self.data))
```

One more thing before we move on. I’m adding a nice convenience function to `Tensor.backward()` that makes it so you don’t have to pass in a gradient of 1s the first time you call `.backward()`. It’s not, strictly speaking, necessary—but it’s handy.

### Nonlinearity layers

#### Let’s add nonlinear functions to Tensor and then create some layer types

For the next chapter, you’ll need `.sigmoid()` and `.tanh()`. Let’s add them to the `Tensor` class. You learned about the derivative for both quite some time ago, so this should be easy:

```
123456789101112131415def sigmoid(self):
    if(self.autograd):
        return Tensor(1 / (1 + np.exp(-self.data)),
                      autograd=True,
                      creators=[self],
                      creation_op="sigmoid")
    return Tensor(1 / (1 + np.exp(-self.data)))

def tanh(self):
    if(self.autograd):
        return Tensor(np.tanh(self.data),
                      autograd=True,
                      creators=[self],
                      creation_op="tanh")
    return Tensor(np.tanh(self.data))
```

The following code shows the backprop logic added to the `Tensor.backward()` method:

```
1234567if(self.creation_op == "sigmoid"):
    ones = Tensor(np.ones_like(self.grad.data))
    self.creators[0].backward(self.grad * (self * (ones - self)))

if(self.creation_op == "tanh"):
    ones = Tensor(np.ones_like(self.grad.data))
    self.creators[0].backward(self.grad * (ones - (self * self)))
```

Hopefully, this feels fairly routine. See if you can make a few more nonlinearities as well: try `HardTanh` or `relu`.

```
123456class Tanh(Layer):                          class Sigmoid(Layer):
    def __init__(self):                         def __init__(self):
        super().__init__()                          super().__init__()

     def forward(self, input):                  def forward(self, input):
         return input.tanh()                        return input.sigmoid()
```

Let’s try out the new nonlinearities. New additions are in bold:

```
123456789101112131415161718192021import numpy
np.random.seed(0)

data = Tensor(np.array([[0,0],[0,1],[1,0],[1,1]]), autograd=True)
target = Tensor(np.array([[0],[1],[0],[1]]), autograd=True)

model = Sequential([Linear(2,3), Tanh(), Linear(3,1), Sigmoid()])
criterion = MSELoss()

optim = SGD(parameters=model.get_parameters(), alpha=1)

for i in range(10):

    pred = model.forward(data)

    loss = criterion.forward(pred, target)

    loss.backward(Tensor(np.ones_like(loss.data)))
    optim.step()
    print(loss)
```

```
12345678910[1.06372865]
[0.75148144]
[0.57384259]
[0.39574294]
[0.2482279]
[0.15515294]
[0.10423398]
[0.07571169]
[0.05837623]
[0.04700013]
```

As you can see, you can drop the new `Tanh()` and `Sigmoid()` layers into the input parameters to `Sequential()`, and the neural network knows exactly how to use them. Easy!

In the previous chapter, you learned about recurrent neural networks. In particular, you trained a model to predict the next word, given the previous several words. Before we finish this chapter, I’d like for you to translate that code into the new framework. To do this, you’ll need three new layer types: an embedding layer that learns word embeddings, an RNN layer that can learn to model sequences of inputs, and a softmax layer that can predict a probability distribution over labels.

### The embedding layer

#### An embedding layer translates indices into activations

In [chapter 11](/book/grokking-deep-learning/chapter-11/ch11), you learned about word embeddings, which are vectors mapped to words that you can forward propagate into a neural network. Thus, if you have a vocabulary of 200 words, you’ll also have 200 embeddings. This gives the initial spec for creating an embedding layer. First, initialize a list (of the right length) of word embeddings (of the right size):

```
12345678910class Embedding(Layer):

    def __init__(self, vocab_size, dim):
        super().__init__()

        self.vocab_size = vocab_size
        self.dim = dim

        weight = np.random.rand(vocab_size, dim) - 0.5) / dim
```

So far, so good. The matrix has a row (vector) for each word in the vocabulary. Now, how will you forward propagate? Well, forward propagation always starts with the question, “How will the inputs be encoded?” In the case of word embeddings, you obviously can’t pass in the words themselves, because the words don’t tell you which rows in `self.weight` to forward propagate with. Instead, as you hopefully remember from [chapter 11](/book/grokking-deep-learning/chapter-11/ch11), you forward propagate indices. Fortunately, NumPy supports this operation:

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0255-01_alt.jpg)

Notice how, when you pass a matrix of integers into a NumPy matrix, it returns the same matrix, but with each integer replaced with the row the integer specified. Thus a 2D matrix of indices turns into a 3D matrix of embeddings (rows). This is perfect!

### Adding indexing to autograd

#### Before you can build the embedding layer, autograd needs to support indexing

In order to support the new embedding strategy (which assumes words are forward propagated as matrices of indices), the indexing you played around with in the previous section must be supported by autograd. This is a pretty simple idea. You need to make sure that during backpropagation, the gradients are placed in the same rows as were indexed into for forward propagation. This requires that you keep around whatever indices were passed in, so you can place each gradient in the appropriate location during backpropagation with a simple `for` loop:

```
12345678910def index_select(self, indices):

    if(self.autograd):
        new = Tensor(self.data[indices.data],
                     autograd=True,
                     creators=[self],
                     creation_op="index_select")
        new.index_select_indices = indices
        return new
    return Tensor(self.data[indices.data])
```

First, use the NumPy trick you learned in the previous section to select the correct rows:

```
1234567             if(self.creation_op == "index_select"):
                 new_grad = np.zeros_like(self.creators[0].data)
                 indices_ = self.index_select_indices.data.flatten()
                 grad_ = grad.data.reshape(len(indices_), -1)
                 for i in range(len(indices_)):
                     new_grad[indices_[i]] += grad_[i]
                 self.creators[0].backward(Tensor(new_grad))
```

Then, during `backprop()`, initialize a new gradient of the correct size (the size of the original matrix that was being indexed into). Second, flatten the indices so you can iterate through them. Third, collapse `grad_` to a simple list of rows. (The subtle part is that the list of indices in `indices_` and the list of vectors in `grad_` will be in the corresponding order.) Then, iterate through each index, add it into the correct row of the new gradient you’re creating, and backpropagate it into `self.creators[0]`. As you can see, `grad_[i]` correctly updates each row (adds a vector of 1s, in this case) in accordance with the number of times the index is used. Indices 2 and 3 update twice (in bold):

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0256-01_alt.jpg)

### The embedding layer (revisited)

#### Now you can finish forward propagation using the new .index_select() method

For forward prop, call `.index_select()`, and autograd will handle the rest:

```
12345678910111213141516class Embedding(Layer):

    def __init__(self, vocab_size, dim):
        super().__init__()

        self.vocab_size = vocab_size
        self.dim = dim

        weight = np.random.rand(vocab_size, dim) - 0.5) / dim
        self.weight = Tensor((weight, autograd=True)

        self.parameters.append(self.weight)

    def forward(self, input):
        return self.weight.index_select(input)
```

```
12345678910111213141516171819data = Tensor(np.array([1,2,1,2]), autograd=True)
target = Tensor(np.array([[0],[1],[0],[1]]), autograd=True)

embed = Embedding(5,3)
model = Sequential([embed, Tanh(), Linear(3,1), Sigmoid()])
criterion = MSELoss()

optim = SGD(parameters=model.get_parameters(), alpha=0.5)

for i in range(10):

    pred = model.forward(data)

    loss = criterion.forward(pred, target)

    loss.backward(Tensor(np.ones_like(loss.data)))
    optim.step()
    print(loss)
```

```
123456[0.98874126]
[0.6658868]
[0.45639889]
    ...
[0.08731868]
[0.07387834]
```

In this neural network, you learn to correlate input indices 1 and 2 with the prediction 0 and 1. In theory, indices 1 and 2 could correspond to words (or some other input object), and in the final example, they will. This example was to show the embedding working.

### The cross-entropy layer

#### Let’s add cross entropy to the autograd and create a layer

Hopefully, at this point you’re starting to feel comfortable with how to create new layer types. Cross entropy is a pretty standard one that you’ve seen many times throughout this book. Because we’ve already walked through how to create several new layer types, I’ll leave the code here for your reference. Attempt to do it yourself before copying this code.

```
12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061def cross_entropy(self, target_indices):

         temp = np.exp(self.data)
         softmax_output = temp / np.sum(temp,
                                        axis=len(self.data.shape)-1,
                                        keepdims=True)

         t = target_indices.data.flatten()
         p = softmax_output.reshape(len(t),-1)
         target_dist = np.eye(p.shape[1])[t]
         loss = -(np.log(p) * (target_dist)).sum(1).mean()

         if(self.autograd):
             out = Tensor(loss,
                          autograd=True,
                          creators=[self],
                          creation_op="cross_entropy")
             out.softmax_output = softmax_output
             out.target_dist = target_dist
             return out

         return Tensor(loss)


                 if(self.creation_op == "cross_entropy"):
                     dx = self.softmax_output - self.target_dist
                     self.creators[0].backward(Tensor(dx))


class CrossEntropyLoss(object):

       def __init__(self):
           super().__init__()

       def forward(self, input, target):
           return input.cross_entropy(target)

import numpy
np.random.seed(0)

# data indices
data = Tensor(np.array([1,2,1,2]), autograd=True)

# target indices
target = Tensor(np.array([0,1,0,1]), autograd=True)

model = Sequential([Embedding(3,3), Tanh(), Linear(3,4)])
criterion = CrossEntropyLoss()

optim = SGD(parameters=model.get_parameters(), alpha=0.1)

for i in range(10):

    pred = model.forward(data)

    loss = criterion.forward(pred, target)

    loss.backward(Tensor(np.ones_like(loss.data)))
    optim.step()
    print(loss)
```

```
123456789101.3885032434928422
0.9558181509266037
0.6823083585795604
0.5095259967493119
0.39574491472895856
0.31752527285348264
0.2617222861964216
0.22061283923954234
0.18946427334830068
0.16527389263866668
```

Using the same cross-entropy logic employed in several previous neural networks, you now have a new loss function. One noticeable thing about this loss is different from others: both the final `softmax` and the computation of the loss are within the loss class. This is an extremely common convention in deep neural networks. Nearly every framework will work this way. When you want to finish a network and train with cross entropy, you can leave off the `softmax` from the forward propagation step and call a cross-entropy class that will automatically perform the `softmax` as a part of the loss function.

The reason these are combined so consistently is performance. It’s much faster to calculate the gradient of `softmax` and negative log likelihood together in a cross-entropy function than to forward propagate and backpropagate them separately in two different modules. This has to do with a shortcut in the gradient math.

### The recurrent neural network layer

#### By combining several layers, you can learn over time series

As the last exercise of this chapter, let’s create one more layer that’s the composition of multiple smaller layer types. The point of this layer will be to learn the task you finished at the end of the previous chapter. This layer is the *recurrent layer*. You’ll construct it using three linear layers, and the `.forward()` method will take both the output from the previous hidden state and the input from the current training data:

```
123456789101112131415161718192021222324252627282930313233class RNNCell(Layer):

    def __init__(self, n_inputs,n_hidden,n_output,activation='sigmoid'):
        super().__init__()

        self.n_inputs = n_inputs
        self.n_hidden = n_hidden
        self.n_output = n_output

        if(activation == 'sigmoid'):
            self.activation = Sigmoid()
        elif(activation == 'tanh'):
            self.activation == Tanh()
        else:
            raise Exception("Non-linearity not found")

        self.w_ih = Linear(n_inputs, n_hidden)
        self.w_hh = Linear(n_hidden, n_hidden)
        self.w_ho = Linear(n_hidden, n_output)

        self.parameters += self.w_ih.get_parameters()
        self.parameters += self.w_hh.get_parameters()
        self.parameters += self.w_ho.get_parameters()

    def forward(self, input, hidden):
        from_prev_hidden = self.w_hh.forward(hidden)
        combined = self.w_ih.forward(input) + from_prev_hidden
        new_hidden = self.activation.forward(combined)
        output = self.w_ho.forward(new_hidden)
        return output, new_hidden

    def init_hidden(self, batch_size=1):
        return Tensor(np.zeros((batch_size,self.n_hidden)),autograd=True)
```

It’s out of scope for this chapter to reintroduce RNNs, but it’s worth pointing out the pieces that should be familiar already. RNNs have a state vector that passes from timestep to timestep. In this case, it’s the variable `hidden`, which is both an input parameter and output variable to the `forward` function. RNNs also have several different weight matrices: one that maps input vectors to hidden vectors (processing input data), one that maps from hidden to hidden (which updates each hidden vector based on the previous), and optionally a hidden-to-output layer that learns to make predictions based on the hidden vector. This RNNCell implementation includes all three. The `self.w_ih` layer is the input-to-hidden layer, `self.w_hh` is the hidden-to-hidden layer, and `self.w_ho` is the hidden-to-output layer. Note the dimensionality of each. The input size of `self.w_ih` and the output size of `self.w_ho` are both the size of the vocabulary. All other dimensions are configurable based on the `n_hidden` parameter.

Finally, an `activation` input parameter defines which nonlinearity is applied to hidden vectors at each timestep. I’ve added two possibilities (`Sigmoid` and `Tanh`), but there are many options to choose from. Let’s train a network:

```
123456789101112131415161718192021222324252627282930313233343536373839404142import sys,random,math
from collections import Counter
import numpy as np

f = open('tasksv11/en/qa1_single-supporting-fact_train.txt','r')
raw = f.readlines()
f.close()

tokens = list()
for line in raw[0:1000]:
    tokens.append(line.lower().replace("\n","").split(" ")[1:])

new_tokens = list()
for line in tokens:
    new_tokens.append(['-'] * (6 - len(line)) + line)
tokens = new_tokens

vocab = set()
for sent in tokens:
    for word in sent:
        vocab.add(word)

vocab = list(vocab)

word2index = {}
for i,word in enumerate(vocab):
    word2index[word]=i

def words2indices(sentence):
    idx = list()
    for word in sentence:
        idx.append(word2index[word])
    return idx

indices = list()
for line in tokens:
    idx = list()
    for w in line:
        idx.append(word2index[w])
    indices.append(idx)

data = np.array(indices)
```

#### You can learn to fit the task you previously accomplished in the - preceding chapter

Now you can initialize the recurrent layer with an embedding input and train a network to solve the same task as in the previous chapter. Note that this network is slightly more complex (it has one extra layer) despite the code being much simpler, thanks to the little framework.

```
embed = Embedding(vocab_size=len(vocab),dim=16)
model = RNNCell(n_inputs=16, n_hidden=16, n_output=len(vocab))

criterion = CrossEntropyLoss()
params = model.get_parameters() + embed.get_parameters()
optim = SGD(parameters=params, alpha=0.05)
```

First, define the input embeddings and then the recurrent cell. (Note that *cell* is a conventional name given to recurrent layers when they’re implementing only a single recurrence. If you created another layer that provided the ability to configure arbitrary numbers of cells together, it would be called an RNN, and `n_layers` would be an input parameter.)

```
1234567891011121314151617181920for iter in range(1000):
    batch_size = 100
    total_loss = 0

    hidden = model.init_hidden(batch_size=batch_size)

    for t in range(5):
        input = Tensor(data[0:batch_size,t], autograd=True)
        rnn_input = embed.forward(input=input)
        output, hidden = model.forward(input=rnn_input, hidden=hidden)

    target = Tensor(data[0:batch_size,t+1], autograd=True)
    loss = criterion.forward(output, target)
    loss.backward()
    optim.step()
    total_loss += loss.data
    if(iter % 200 == 0):
        p_correct = (target.data == np.argmax(output.data,axis=1)).mean()
        print_loss = total_loss / (len(data)/batch_size)
        print("Loss:",print_loss,"% Correct:",p_correct)
```

```
12345Loss: 0.47631100976371393 % Correct: 0.01
Loss: 0.17189538896184856 % Correct: 0.28
Loss: 0.1460940222788725 % Correct: 0.37
Loss: 0.13845863915406884 % Correct: 0.37
Loss: 0.135574472565278 % Correct: 0.37
```

```
123456789101112131415batch_size = 1
hidden = model.init_hidden(batch_size=batch_size)
for t in range(5):
    input = Tensor(data[0:batch_size,t], autograd=True)
    rnn_input = embed.forward(input=input)
    output, hidden = model.forward(input=rnn_input, hidden=hidden)

target = Tensor(data[0:batch_size,t+1], autograd=True)
loss = criterion.forward(output, target)

ctx = ""
for idx in data[0:batch_size][0][0:-1]:
    ctx += vocab[idx] + " "
print("Context:",ctx)
print("Pred:", vocab[output.data.argmax()])
```

```
12Context: - mary moved to the
Pred: office.
```

As you can see, the neural network learns to predict the first 100 examples of the training dataset with an accuracy of around 37% (near perfect, for this toy task). It predicts a plausible location for Mary to be moving toward, much like at the end of [chapter 12](/book/grokking-deep-learning/chapter-12/ch12).

### Summary

#### Frameworks are efficient, convenient abstractions of forward and backward logic

I hope this chapter’s exercise has given you an appreciation for how convenient frameworks can be. They can make your code more readable, faster to write, faster to execute (through built-in optimizations), and much less buggy. More important, this chapter will prepare you for using and extending industry standard frameworks like PyTorch and TensorFlow. Whether debugging existing layer types or prototyping your own, the skills you’ve learned here will be some of the most important you acquire in this book, because they bridge the abstract knowledge of deep learning from previous chapters with the design of real-world tools you’ll use to implement models in the future.

The framework that’s most similar to the one built here is PyTorch, and I highly recommend diving into it when you complete this book. It will likely be the framework that feels most familiar.
