# 序言

# 1. 需求
客户端与服务端基于`HTTP`协议进行交互，每个请求报文都会有公共的参数和报文头字段，请求报文`Body`的序列化方式可能是`JSON`或者`URLEncode`，响应报文`Body`的反序列化方式也可能是`JSON`或者`URLEncode`，反序列化后得到的数据会存在多种结构和字段名。

这是一个简化后的真实需求，是我入职上一家公司时所面对的坑。

# 2. 分析与设计
确定需求后，我们需要对需求进行分析与设计，这个过程是包括，抽象关键对象，抽象对象之间的共性，设计对象的关系与交互，确定实现方式以及边界问题。

## 2.1 提取关键抽象
首先从需求中我们得知客户端与服务端是基于`HTTP`协议进行交互，而`HTTP`的基本交互就是在一个`HTTP`会话中进行一问一答，客户端向服务端发送请求，服务端对请求进行响应。从这个交互过程中我们可以抽象出的对象是`HTTP`会话`HTTPSession`，请求`Request`与响应`Response`。

每个请求报文都会有公共的参数和报文头字段，而这些公共信息可以是编译期决定的，也可以是运行时动态添加或修改，所以我们需要一个对象来管理这些公共信息`RequestGeneralInfo`。

请求报文`Body`的序列化方式可能是`JSON`或`URLEncode`，既然是存在多种Body的序列化方式，所以这里可以直接抽象出两个的对象`RequestBodyJSONSerializer`和`RequestBodyURLEncodeSerializer`。

响应报文`Body`的反序列化方式也可能是`JSON`或`URLEncode`，在这里我们可以抽象出两个的对象`ResponseBodyJSONSerializer`和`ResponseBodyURLEncodeSerializer`。

## 2.2 对象抽象视图
我们从需求中提取出关键对象后，接下来要定义这些对象的抽象视图。这些关键对象都是基于某种动机抽象出来的，我们可以根据抽象动机来定义这些对象的初始行为(也可以叫接口或操作)和属性。首先来看`HTTPSession`这个对象，它是用来抽象`HTTP`会话，所以它的行为和属性可以根据`HTTP`会话来定义。

![HTTPSession2](https://upload-images.jianshu.io/upload_images/711081-0d62e28280ebcb20.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

`HTTP`会话的交互大概就像上图那样，发送一个`Request`，接收一个`Response`并回反馈，所以`HTTPSession`对象具有发送`Request`的行为，以及接收并回调`Response`的行为，虽然`HTTP`会话是一问一答的方式进行交互，但是`HTTP`会话可以提前缓冲一组`Request`，只是这些`Request`是按顺序来发送并接收响应的，所以有当前`Request`集合的属性，接收到`Response`后我们需要把信息回调给相应的客户对象，所以有客户对象集合的属性，根据这些基础的信息我们可以得到`HTTPSession`对象的初始行为和属性以及基础抽象视图。

![HTTPSessionView](https://upload-images.jianshu.io/upload_images/711081-d8530f02686cf3e2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

`Request`对象和`Response`对象分别抽象了HTTP请求报文和响应报文，所以可以由此根据来定义它们的初始行为和属性。

![RequestAndResponse2](https://upload-images.jianshu.io/upload_images/711081-f17ffcb8532e787d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

`RequestGeneralInfo`对象只是用来存储公共参数和报文头字段，所以行为和属性的定义比较简单。

![RequestGeneralInfo3](https://upload-images.jianshu.io/upload_images/711081-ead1631565d54d3e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

虽然请求报文和响应报文`Body`的序列化对象有多个，但由于动机明确，职责单一，都只是用来做参数的序列化工作，所以行为和属性比较简单。

![RequestBodySerialize](https://upload-images.jianshu.io/upload_images/711081-46d48e86c23d14a1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![ResponseBodySerialize](https://upload-images.jianshu.io/upload_images/711081-0e94ed274a344681.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 2.3 抽象交互过程
我们定义了关键对象的初始行为和属性，以及这些对象的基础抽象视图。这些对象是否已经可以满足我们的需求？我们尝试使用这些对象来解决需求问题。

这里解释一下什么是客户对象，什么是服务对象，对象A向对象B发送消息，对象B响应消息并提供相应服务，在这个场景下，对象A就是客户对象，对象B就是服务对象。举个例子，`ViewController`对象向`Model`对象发送获取数据的消息，`Model`对象接收消息并返回数据给`ViewController`对象，那`ViewController`对象就是客户对象，而`Model`对象就是服务对象。

![Scene1_1](https://upload-images.jianshu.io/upload_images/711081-e0704591f42c209e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图我们可以看到，客户对象跟这些基础对象一顿交互后，确实已经解决了基本的需求问题。但同时我们也发现，对于所有需要进行`HTTP`交互的客户对象而言，这一烦琐的交互过程都是必不可少的，一百个客户对象就会有一百份相同的交互代码。有一百份相同的代码看上去好像也没什么问题，顶多不就是冗余代码多一点，以后优化一下交互过程，瞬间代码量减少了一个量级，今年安装包瘦身的`KPI`又完成了，从这个角度来看，CV大法是真的香！

我们现在来考虑后期维护的问题，假设参与这个交互过程的其中一个服务对象的行为发生了变化，怎么办？还能怎么办，加班改啊。对象行为的改变是后期维护比较常见的情况，通过修改一百份相同的代码来进行维护，这种方式本身就非常低效。

现在所遇到的问题是存在重复的交互过程，我们可以尝试把这个交互过程抽象成一个操作对象`HTTPJSONOperation`来复用这个交互过程。我们再进行上面的交互时，只需要去创建一个`HTTPJSONOperation`对象，让`HTTPJSONOperation`对象代替客户对象去完成烦琐的交互，最后把结果返回给相应的客户对象即可。

![HTTPJSONOperation2](https://upload-images.jianshu.io/upload_images/711081-52c818af9310d8b1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，我们即减少了代码的冗余量，同时当某些服务对象的行为发生变化时，我们只需要改变`HTTPJSONOperation`对象的实现即可，这对客户对象并没有产生什么影响，所以客户对象的稳定性就提高了。

虽然抽象出`HTTPJSONOperation`对象后，整个交互过程被简化了，稳定性也挺高了，但我们回头看一下需求“请求报文`Body`的序列化方式可能是`JSON`或者`URLEncode`，响应报文`Body`的序列化方式也可能是`JSON`或者`URLEncode`”时就会发现另一个问题，`HTTPJSONOperation`对象只能处理JSON类型的交互，而从需求当中我们得知，我们即有`JSON`类型的交互，也有`URLEncode`类型的交互，所以我们现在要处理`URLEncode`类型的交互。

![HTTPURLEncodeOperation2](https://upload-images.jianshu.io/upload_images/711081-26bc80c3811279f0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们可以用相同的方式对`URLEncode`类型的交互进行抽象，抽象出`HTTPURLEncodeOperation`对象后，我们再进行`URLEncode`类型的交互时只需要创建一个`HTTPURLEncodeOperation`对象即可。

![Scene4_1](https://upload-images.jianshu.io/upload_images/711081-3bb20e6f0e595706.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![Scene5_1](https://upload-images.jianshu.io/upload_images/711081-98f8f4c0037ea7c8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上面的两个交互过程我们发现，无论是`JSON`操作对象还是`URLEncode`操作对象都是从`RequestGeneralInfo`对象中获取公共信息，然后再设置`Request`对象，所以这个交互过程是重复的，我们可以用相同的方式来处理，抽象出一个`RequestSetOperation`操作对象来复用这个交互过程，但这里再插入一个`RequestSetOperation`操作对象，那参与整个交互过程的对象又增加了，交互过程也比现在要复杂一些。除了操作对象这种处理方式，我们是否还有别的方式可以解决重复交互过程的问题？

我们观察一下这个重复的交互过程和参与的对象就会发现，`RequestGeneralInfo`对象的职责以及存储的信息都是跟`Request`对象相关，所以我们可以为`RequestGeneralInfo`对象新添加一个行为，把设置`Request`对象的工作交给`RequestGeneralInfo`对象完成。

![RequestGeneralInfo4](https://upload-images.jianshu.io/upload_images/711081-d259f15e90a8c27c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![Scene6_1](media/15881435876723/Scene6_1.png)

## 2.4 共性抽象
在分析与设计过程中，我们常常会抽象出一些职责非常相似的对象，这些对象会存在一定的共性，我们可以尝试抽象这些共性来获得更好的动态性。

通过观察`HTTPJSONOperation`对象和`HTTPURLEncodeOperation`对象后就会发现，这两个对象除了`Body`的序列化/反序列化方式不同以外，无论是行为，属性还是交互方式都是一样的。也就是说，这两个对象的实现大部份都是重复的，我们是否有办法合并这两个对象来进一步减少代码的冗余量呢？

合并两个相似的对象主要要考虑的问题是，怎么兼容不同的部份。一种方式是把所有不同的内容都包含进来，通过枚举类型区分并选择相应的实现方式。

![HTTPOperation6](https://upload-images.jianshu.io/upload_images/711081-616ddba650ce974b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这种方式看上去好像也没什么问题，但当你尝试去扩展一种新的交互类型时，这种方式的缺点就很明显了。首先添加新的枚举值`XML`，然后添加`XML`的序列化/反序列化对象为属性，接下来就是在需要序列化/反序列化时，通过`if else`的方式来选择相应的序列化/反序列化对象。首先这是一种硬编码的扩展方式，其次用这种方式扩展需要打开原始文件以及修改原来已经稳定的实现代码。这些为什么是缺点，这些缺点会带来什么问题，这部份会在后面的内容讲解，这里先假设这种方式是坑爹的。

### 2.4.1 抽象协议
除了上面这种方式，还有没有别的方式可以用来兼容不同的部份呢？我们可以先回过头来观察一下`HTTPOperation`对象与`RequestBodyJSONSerializer`对象以及`RequestBodyURLEncodeSerializer`对象的交互情况。

![HTTPOperationAndRequestBodySerializer](https://upload-images.jianshu.io/upload_images/711081-d4b6285f6b90215a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图的交互流程可以发现，`HTTPOperation`对象无论是跟`RequestBodyJSONSerializer`对象交互，还是跟`RequestBodyURLEncodeSerializer`对象交互，都是向序列化对象发送同一消息，而序列化对象也是以相同的方式返回结果给`HTTPOperation`对象，也就是说，这两个序列化对象有相同的行为，而这个相同的行为被`HTTPOperation`对象所依赖，所以我们可以尝试把这个相同行为做高一层级的抽象(或者叫向上抽象)，抽象成更一般性的协议(或者叫接口)`RequestBodySerializer`，`RequestBodyJSONSerializer`类与`RequestBodyURLEncodeSerializer`类继承(或者叫引入)并实现协议。

![RequestBodySerialize](https://upload-images.jianshu.io/upload_images/711081-20ab9b3fc405c69c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

`HTTPOperation`对象依赖协议提供的服务。

![HTTPOperationNe](https://upload-images.jianshu.io/upload_images/711081-bd3c19a0415abe77.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，`HTTPOperation`对象只知道`RequestBodySerializer`协议提供的服务，但`HTTPOperation`对象并不知道具体是哪个对象提供的，当我们想进行某类型的交互时，只需要给`HTTPOperation`对象传相应类型的`RequestBodySerializer`对象即可。扩展新的交互方式时，我们只需要把新抽象的对象实现`RequestBodySerializer`协议，我们就可以用新的方式进行交互，而这种扩展并不需要打开和修改`HTTPOperation`对象的实现代码，就可以复用`HTTPOperation`对象的整套交互流程，这种动态扩展后面会详细讲解。

`ResponseBodyJSONSerializer`和`ResponseBodyURLEncodeSerializer`对象可以用相同的方式处理，抽象出`ResponseBodySerializer`协议，这里就不再描述推导过程。

### 2.4.2 进一步抽象交互过程
![Scene2_2](https://upload-images.jianshu.io/upload_images/711081-a811f1c776dcd387.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

通过抽象协议，我们合并了操作对象，且操作对象的复用性更强了，但整个交互过程看上去还是比较烦琐，我们是否可以简化这个流程，或者减少一些交互的对象呢？

我们回过头来观察一下整个交互过程可以发现，`RequestGeneralInfo`对象和`RequestBodySerializer`对象具有相似的职责，都是跟`Request`对象的序列化相关，只是各自负责的部份不同，我们是否可以利用这一点来做些什么呢？

我们可以尝试合并这两个对象的职责，现在把`RequestGeneralInfo`对象的职责添加到`RequestBodySerializer`对象上。

![RequestBodySerializerAndInfo2](https://upload-images.jianshu.io/upload_images/711081-104a734e46fa4530.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们得到了一个新的对象`RequestSerializer`，这个对象负责管理公共信息以及将相关信息序列化，现在用`RequestSerializer`对象来进行交互。

![HTTPSessionAndRequestSerializer](https://upload-images.jianshu.io/upload_images/711081-04530d4653fff2f7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，使用`RequestSerializer`对象后，整个交互过程确实是简化了，`RequestSerializer`对象完成了设置以及序列化`Request`对象。但我们回头看需求时就会发现这种方式又来带了另外一些问题，“请求报文`Body`的序列化方式可能是`JSON`或者`URLEncode`”，为了可以进行`JSON`类型和`URLEncode`类型的交互，所以我们需要在程序运行时同时持有`RequestBodyJSONSerializer`对象和`RequestBodyURLEncodeSerializer`对象，这两个对象都保存了公共信息，也就是在程序运行时相同的数据有两份，当公共信息需要更新时，需要同时更新这两个对象。合并这两个对象的职责似乎并不是一个好的选择，所以我们需要再回过头来观察交互过程。

![Scene2_2](https://upload-images.jianshu.io/upload_images/711081-a811f1c776dcd387.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，`RequestGeneralInfo`对象的工作和`RequestBodySerializer`对象的工作存在一定关联，`HTTPOperation`对象先跟`RequestGeneralInfo`对象交互，设置`Request`对象，然后`RequestBodySerializer`对象再去序列化`Request`对象，也就是说，`RequestBodySerializer`对象的工作是建立在`RequestGeneralInfo`对象产物的基础上进行的，所以我们可以尝试把`RequestGeneralInfo`对象作为`RequestBodySerializer`对象的一部份进行对象组合。

![RequestBodySerializerAndGeneralInfo](https://upload-images.jianshu.io/upload_images/711081-06dc125b995d986f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

当`HTTPOperation`对象需要对`Request`对象进行序列化时，发送序列化消息给`RequestBodySerializer`对象，`RequestBodySerializer`对象再发送设置`Request`对象的消息给`RequestGeneralInfo`对象，当`RequestGeneralInfo`对象完成设置`Request`对象时，`RequestBodySerializer`对象再序列化`Request`对象，并把结果返回给`HTTPOperation`对象。

![Scene7_1](https://upload-images.jianshu.io/upload_images/711081-fafc94295394450f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，站在`HTTPOperation`对象的视角来看，整个交互过程是简化了，因为`HTTPOperation`对象需要交互的对象减少了，同时在程序运行时也只需存在一个`RequestGeneralInfo`对象，即公共信息在程序运行时只有一份。

观察`RequestGeneralInfo`对象和`RequestBodySerializer`对象可以发现它们存在相同的行为，而它们之间的关系又是紧密的，所以我们可以抽象它们的共性。我们在前面也发现了，`RequestBodySerializer`对象的工作是建立在`RequestGeneralInfo`对象的产物的基础上进行的，我们可以抽象这一概念，即`RequestBodySerializer`对象作为一个序列化对象，它的工作是建立在另一个序列化对象的产物的基础上进行的。基于这些概念我们可以抽象出一个新的类层次结构。

![RequestBodySerializerNe](https://upload-images.jianshu.io/upload_images/711081-1d2603a561af2c10.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们现在来看看这些对象运行时的关系。

![HTTPOperationRelation1_1](https://upload-images.jianshu.io/upload_images/711081-fc5c0b83a5c4975a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![Scene3_2](https://upload-images.jianshu.io/upload_images/711081-b47403f06618fe42.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，我们进一步简化了`HTTPOperation`对象的交互过程，同时也把这个交互过程的抽象级别又提高了一层。对于`HTTPOperation`对象而言，它只知道`RequestSerializer`对象是用来序列化`Request`对象，至于`RequestSerializer`对象是一个组合对象还是单一对象，这对于`HTTPOperation`对象是透明的。

![RequestSerializerLevel](https://upload-images.jianshu.io/upload_images/711081-b6b2be6844e9f86a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们可以基于前面总结出来的抽象概念以及`RequestSerializer`协议做更多更复杂的扩展，可以设计复杂的序列化过程。在任一分支上的所有`RequestSerializer`对象都是通过在前一个`RequestSerializer`对象产物的基础上做进一步的序列化工作，在这里我们就得到了一种可以动态扩展的模式。

到此为止，我们基本上已经处理完请求报文的问题，接下来处理响应报文的问题。

### 2.4.3 个体与整体的抽象
![ResponseBodySerializerNe](https://upload-images.jianshu.io/upload_images/711081-fe54986a59ccd1f0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

上图是我们在前面得到的`ResponseBodySerializer`协议，响应报文的处理跟请求报文的处理有些不同，我们可以从响应报文头字段知道`Body`是用什么方式序列化，我们用相同的方式进行反序列化即可得到数据，所以我们不必将响应报文的反序列化方式跟`HTTP`交互一一捆绑起来。正常情况下，服务端也可以根据请求报文头字段的信息对`Body`进行反序列化，如果服务端愿意配合客户端的话。

![HTTPOperationAndResponseBodySerializer](https://upload-images.jianshu.io/upload_images/711081-8131feb3aafed657.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们需要做的是统一处理响应报文`Body`的反序列化，所以我们可以
基于`ResponseBodySerializer`协议抽象出一个新的具体对象。

![ResponseBodyComposeSerializer](https://upload-images.jianshu.io/upload_images/711081-b15bd84de5330d82.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这个对象是一个`聚合体`，我们可以动态向`ResponseBodyComposeSerializer`对象添加所需要的`ResponseBodySerializer`对象。当`HTTPOperation`对象向`ResponseBodyComposeSerializer`对象发送反序列化消息时，`ResponseBodyComposeSerializer`对象把消息转发给当前保存的`ResponseBodySerializer`对象处理即可，这样我们就保证了`ResponseBodyComposeSerializer`对象可动态扩展性和稳定性，我们又得到了一种可以动态扩展的模式。

## 2.5 操作对象管理
通过进一步的分析与设计，我们不仅解决了重复交互过程的问题，还得到了一个可以动态扩展，复用性强的`HTTPOperation`对象。我们把交互过程抽象以后，这个交互过程在未来进行调整也不会影响客户对象，程序的稳定性也得到了提升。

![ClientAndHTTPOperation2](https://upload-images.jianshu.io/upload_images/711081-5081aa69737f4165.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

通过观察客户对象与`HTTPOperation`对象的交互，我们又有新的发现，由于`HTTPOperation`对象是一个抽象化的交互过程，所以客户对象需要给`HTTPOperation`对象传递相应的实体对象，让这些实体对象参与这个交互过程，而这个传递过程对于每一个客户对象来说都是重复的，而且从前面的分析与设计的经验我们知道，一个对象对另一个对象行为的依赖越强，交互越紧密，它们之间的耦合度就越高，耦合度就越高后期扩展和维护就越难，很容易会出现改一个对象把整个系统都改崩了，俗称“牵一发动全身”。

我们发现客户对象不仅负责传递实体对象，还负责创建并管理这些实体对象，并且还要管理`HTTPOperation`对象，但我们也发现这几个行为是相关的，所以我们可以尝试抽象一个对象来完成这些操作，对象抽象的动机也很明确，就是负责创建并管理相关的实体对象，负责设置并管理`HTTPOperation`对象。

![HTTPOperationManage](https://upload-images.jianshu.io/upload_images/711081-10439cbba187ebee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们可以在程序运行时创建一个生命周期与程序生命相同的`HTTPOperationManager`对象，这个对象用来存储最常用到的相关实体对象，这样我们就可以用这个对象来创建并管理最常用的`HTTPOperation`对象，我们也可以在获取到`HTTPOperation`对象后进行特殊的处理。我们不仅减少了客户对象的依赖，同时要解决了重复交互过程以及管理的问题。

## 2.6 实现方式与边界问题
![HTTPNetwork3](https://upload-images.jianshu.io/upload_images/711081-94daa7625868228d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

经过一轮又一轮的分析与设计，我们得到了一个基础框架`HTTPNetwork`，以及基于这个基础框架所做的扩展，但我们在前面做的工作只是把需求变现，设计了对象之间的关系，接下来我们考虑对象的实现以及对象之间的边界问题。正常情况下，这个过程可能会对现有的框架和架构做一些微调整，可能会适当调整对象的抽象视图，也可能会抽象出一些新的对象。

我们先来看`HTTPOperation`对象，`HTTPOperation`对象是抽象了`HTTP`的交互过程，这里需要考虑的是，这个`HTTP`交互过程是同步还是异步，是单线程环境还是多线程环境，运行环境由哪个对象提供，开始交互后是否还能改变参与交互过程的对象，交互完成后回调方式以及回调环境，存在多种回调方式还是单一回调方式，交互是否可以取消。

`HTTPOperationManager`对象是用来管理`HTTPOperation`对象和参与`HTTP`交互的相关对象，初始化`HTTPOperationManager`对象后还能不能改变参与`HTTP`交互的相关对象，如果能改变，当前已运行或待运行的`HTTPOperation`对象是否更新相应的对象，`HTTPOperationManager`对象用方式来存储`HTTPOperation`对象，`HTTPOperationManager`对象是否为`HTTPOperation`对象提供运行环境，是否需要控制`HTTPOperation`对象运行的最大并发数，等等

上面提出了很多问题，这里就不给出什么答案了，如果把所有的问题和解决方式的优缺点都列清清楚楚楚，那真是写到明年都写不完，用一话广东话来形容，写到蚊都训啦。

实现方式的选择可能产生的影响，举个例子，`HTTPOperationManager`对象需要控制`HTTPOperation`对象运行的最大并发数，而最大并发数是可设置的，所以我们需要为`HTTPOperationManager`对象添加新的行为，这样就改变了对象的抽象视图。为了方便存储和管理`HTTPOperation`对象，我们可以抽象一个新的数据结构对象来完成这一工作。

当我们做完分析与设计，考虑清楚实现方式和边界问题后，我们就可以开始动手写代码，不过这个时候的写代码基本上就是打字了。

# 3. 设计模式
平时跟朋友，同事或者网友沟通交流过程中发现一个现象，有很多开发者对设计模式和设计原则这些抽象理论概念很熟，但面对真实需求的时候就是不知道怎么动手做设计，这好像是一个比较普遍的现象。

鲁迅曾经说过“世界上本没有设计模式，相似的对象交互及关系用多了，便成了设计模式”。设计模式是前人在摸索对象之间的关系及交互，通过一个又一个的实例，不断实践，把一个个相似的场景总结出来的高级抽象概念，所以你纯粹去背设计模式和设计原则，做不出设计不挺正常的。我没有经济学基础，就去听了一次巴菲特的讲座，我就能成为一个经济学家，那真是有鬼了。

在前面的分析与设计过程中，我并没有提及设计模式，设计原则或者一些过于抽象的理论概念，甚至刻意去回避这些东西，纯粹站在面向对象的角度进行分析与设计，最终我们也可以设计出一个基础框架，也可以得到一个解决方案。我们在摸索对象之间的关系及交互时所总结出来的模式，也可能就是现在的设计模式。

![RequestBodySerializerNe](https://upload-images.jianshu.io/upload_images/711081-1d2603a561af2c10.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![HTTPOperationRelation1_1](https://upload-images.jianshu.io/upload_images/711081-fc5c0b83a5c4975a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们回头看“2.4.2-进一步抽象交互过程”。`RequestGeneralInfo`对象和`RequestBodySerializer`对象具有相同的行为，`RequestBodySerializer`对象的工作是基于`RequestGeneralInfo`对象的产物进行的，也就是说`RequestBodySerializer`对象动态扩展了`RequestGeneralInfo`对象，最后我们总结出来的模式就是现有的装饰模式。我们在“2.4.3-个体与整体的抽象”总结出来的就是现有的组合模式。

很多时候在你考虑对象之间，类之间的关系及交互时，你不一定可以找到相应的设计模式用，这个时候就要考验你面向对象的基础了。抽象理论概念很熟但不知道怎么动手做设计，这个坑我以前也踩过，我分享一下我自己的学习经历(嗯，接下来开始编故事了)，希望对你有帮助。

我最初想学怎么做面向对象设计的时候，也是直接看的设计模式和设计原则，在学习的头一年我基本上都能把整本《GoF23》和相关的设计原则背出来，如果单纯讨论设计模式和设计原则这些抽象理论概念，我能吹得头头是道，很像是那么一回事，当我去维护一些现有的库，现有的框架的时候，我也能在原有的基础上套用一些设计模式去做点事情，也因此当时就产生了幻觉，“哦，原来设计模式和设计原则就是这么一回事”。

但当我面对一份陌生的需求，要根据实际情况从0到1做设计的时候就懵逼了，完全都不知道怎么动手。这就好比你去打Dota2，可以自由选英雄，选装备，选等级和技能，然后就打一场后期的团战，然后你发现其中一个队友无论是切入时机，走位，技能释放，装备使用都很像那么一回事，光看这场团战的操作和意识，你都以为他是个大屌，当你跟他组队从开局开始打，你发现他就是一个沙雕，选个SF上来一级升黄点，然后对线期对面6级他才2级，全场被追着提款。

后来我从一个国外的架构师所分享的学习线图中发现，他推荐的设计模式相关的书是《Head First》和《GoF23》，但无论《Head First》还是《GoF23》，都是从另一本书指向过来的，也就是说那本书是基础，那本书是《面向对象分析与设计》，看到这本书的时候我比较疑惑，面向对象技术无论是在学校学到的，还是工作后了解到的，无非不就是封装，继承和多态这三个概念，还有别的什么东西吗？当我花了几个月认认真真把这本书啃下来才发现，还是too young too simple！封装，继承和多态那都只是面向对象技术的冰山一角。

接下来经历了一个比较痛苦的时期，因为要转变思维方式，告别单纯的封装，继承和多态，从头再来。这就像你吹了十年的Saxophone，然后突然发现你的气息和嘴型都是错的，我TMD(挺猛的)......然后通过不断实践，慢慢把思维方式转变过来，相对稳定之后再回头看设计模式和设计原则就清晰多了，而且理解也不一样了。

# 4. 第三方库的处理方式
`AFNetworking`应该算是iOS最常见的网络库了，我们现在尝试用`AFNetworking`来解决我们的需求。`HTTP`交互由`AFNetworking`中的`AFHTTPSessionManager`完成。

响应反序列化`AFHTTPResponseSerializer`跟我们上面分析设计的一样，也是通过组合模式实现的，`AFCompoundResponseSerializer`作为反序列化对象的`聚合体`，保存各种具体的`AFHTTPResponseSerializer`对象。虽然`AFNetworking`没有`URLEncode`类型的反序列化对象，但我们可以继承`AFHTTPResponseSerializer`实现一个`AFURLEncodeResponseSerializer`即可。

![AFHTTPResponseSerializer](https://upload-images.jianshu.io/upload_images/711081-2e6fd7383bb7d08f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


跟我们上面分析与设计不同的是，请求序列化`AFHTTPRequestSerializer`是用策略模式实现的，而且我们的`RequestSerializer`是用装饰模式实现的，设计模式不同就意味着扩展方式不同，实现方式以及对象的责职和边界都不一样。

![AFHTTPRequestSerializer](https://upload-images.jianshu.io/upload_images/711081-69e2cb6ad506470d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们是把`HTTP`交互抽象成一个`HTTPOperation`对象，这样我们就可以根据需求来决定参与`HTTP`交互的对象。在这一点上，`AFHTTPSessionManager`跟`AFHTTPRequestSerializer`是做不到的，虽然我们可以动态设置`AFHTTPSessionManager`相应的`AFHTTPRequestSerializer`对象，但我们不能根据需求对每一次的`HTTP`交互进行设置，`AFHTTPSessionManager`并没有相应的行为可以解决这一问题。

一种解决方式是，我们可以创建两个`AFHTTPSessionManager`对象，一个持有`AFHTTPRequestSerializer`对象，一个持有`AFJSONRequestSerializer`对象，但这种方式我们在上面也推导过，当需要更新请求报文头字段时，必须同时更新`AFHTTPRequestSerializer`对象和`AFJSONRequestSerializer`对象。

另一种解决方式是，我们可以创建一个`AFHTTPSessionManager`分类，在分类添加可以根据需求对每一次的`HTTP`交互进行设置的行为，但这种方式只能用`AFURLSessionManager`对象的行为来实现，而且`AFHTTPSessionManager`整个类基本上是多余了。

`AFNetworking`在这种场景下所表现出来的灵活性是有一点欠缺的，当然这里并不是说`AFNetworking`不好，只是场景不同，`AFNetworking`预设的场景是服务端可以根据请求报文的信息进行反序列化工作的，这种预设的场景更常规，所以`AFNetworking`的请求序列化用策略模式很合理，只是我们实际遇到了奇葩的需求。

# 5. 扩展
到此为止，我们还有一个需求没有解决，“响应报文`Body`的反序列化方式也可能是`JSON`或者`URLEncode`，反序列化后得到的数据会存在多种结构和字段名”，多种数据结构和字段名所产生的影响是显而易见的。

![Scene8_2](https://upload-images.jianshu.io/upload_images/711081-2831ccd60496937f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，当`ViewController`对象接收到响应数据后，`ViewController`对象需要对数据结构进行识别，还要识别不同的字段名，这些识别工作和处理对于每个`ViewController`对象都是一样的，最简单的解决方式就是CV大法，每个`ViewController`都复制一份处理，CV大法的一个问题是会产生大量冗余代码，CV大法最大的问题还不是这个，会出现多种数据结构和字段名这也侧面反映出服务端是比较随便的，后期再次更改数据结构和字段名是大概率发生的事情，所以当数据结构和字段名再次更改时，对`ViewController`的影响就很严重了，这有多恶心就不用多说了。

一种解决方式是，抽象出一种固定的数据结构，`HTTPOperation`对象返回这种固定的数据结构，这就要求`HTTPOperation`对象在接收到响应报文后对数据进行识别和处理，多种数据结构和字段名，所以我们需要抽象多个处理对象。

![ResponseDataStructSerialize](https://upload-images.jianshu.io/upload_images/711081-05fdba3b23f54779.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以看到，我们抽象了这些对象的共性，和响应反序列化一样，我们可以统一处理这些不同的数据结构和字段名，所以这里也可以应用组合模式。

从职责上来看，`ResponseDataStructSerializer`也属于响应反序列化的一部份，而`ResponseDataStructSerializer`对象的工作是在`ResponseBodySerializer`对象的产物的基础上进行的，所以这里可以应用装饰模式对`ResponseDataStructSerializer`对象和`ResponseBodySerializer`对象进行组合。

![ResponseSerialize](https://upload-images.jianshu.io/upload_images/711081-ffeab683be8afef8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这里所做的扩展对原有的`HTTPNetwork`基础框架不会产生影响。这样，`HTTPOperation`对象就可以返回固定的数据结构给`ViewController`对象。

![Scene9_1](https://upload-images.jianshu.io/upload_images/711081-168426a72e54f538.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

后期再更改数据结构和字段名也不会对`ViewController`对象产生影响，因为`ViewController`对象每次拿到的都是统一标准的数据结构。

# 6. 面向对象分析与设计的过程
在前面的分析与设计过程中，我是分了几个阶段来进行，各个阶段关注不同的事情，每个阶段都在上一个阶段的产物的基础上进行。我早期分析与设计的过程不是这样的，我早期的方式是，先总结需求，然后根据需求抽取关键抽象，接下来对象之间的关系和实现方式我会一并考虑。那为什么现在会把分析与设计的过程拆得更细，分更多的阶段进行？主要是因为效率和稳定性。

## 6.1 复杂性与稳定性
我们现在假设需求相对复杂一些，能抽象出三四十个关键对象，面对这么多对象，光去考虑这些对象的关系，这已经是一件复杂的事情，还要去考虑这些对象的交互，考虑交互的时候还会不停地修改对象的抽象视图，调整对象的关系，这又是一件复杂的事情，同时还要考虑这些对象的实现，考虑对象的实现可能又会修改对象的抽象视图，可能会添加一些新的对象。

在这个过程中大概率会出现的情况是，你可能对所有的东西都只是大概是这样子，都是一些模凌两可的想法，或者你大概想好了一些对象的实现方式，但通过进一步的考虑，你可能会合并一些对象，或者在交互过程中发现要拆一些对象，那你刚刚想好的实现基本上就是废了。在你考虑实现的同时去考虑对象之间的交互，很容易就会把两个原本应该独立的对象，实现上做了依赖，当最后你想去改一下某一个对象的实现，可能整份设计都崩了，或者硬挤出来的设计在真实场景中应用时，可能会发现到处都不合适，最后只能推倒重来。这样的稳定性就会很差。

## 6.2 效率
如果目标不明确，准确率低，稳定性差，你就需要不断推倒重来，那你要做出一份合理的设计所花费的时间就会很多，而且你面对一个混乱的局面，你可能连动手的方向都没有。

孔子曾经说过：“人的大脑在同一时间内能关注和处理的事情是有限的”。常规解决复杂问题的方式就是，把大问题拆成一个个可以处理的小问题，再把一个个小问题解决，这样大问题也就解决了。当你把大的过程，拆成多个阶段，每个阶段只专注做一件事件，目标很明确，所以你得到的产物就很稳定，推倒重来的可能性也大大降低了，而且你最后得到的设计的准确率也会很高。










