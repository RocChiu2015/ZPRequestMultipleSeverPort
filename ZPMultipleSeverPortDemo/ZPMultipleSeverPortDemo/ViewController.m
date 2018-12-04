//
//  ViewController.m
//  ZPMultipleSeverPortDemo
//
//  Created by 赵鹏 on 2018/3/8.
//  Copyright © 2018年 赵鹏. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    [self test1];
    
    [self test2];
}

/**
 * 当开始运行下面的这个方法的时候，程序先执行44、45行，然后GCD把任务放到并发队列(queue)中，然后GCD再按照“先进先出，后进后出”的原则把任务再从并发队列中拿出来，因为dispatch_group_async是异步函数，具备创建新的子线程的能力，所以刚才拿出来的任务再被GCD分别放到创建好的两个新的子线程（A、B）中，在新的子线程中同时开始执行任务，所以程序会同时执行48、59行，然后在各自的子线程中再接着运行下面的异步函数(dispatch_async)，此时在A、B子线程中的任务就已经完成了，而不必等异步函数dispatch_async里面的耗时操作完成，并且A、B子线程被销毁。因为是队列组，所以队列组中的两个任务都执行完毕之后，就会执行dispatch_group_notify函数了，所以程序会执行70、72行。接下来要执行异步函数dispatch_async了，同理，GCD先把任务放到并发队列(queue)中，然后GCD再按照既定的原则从并发队列中把任务拿出来，因为dispatch_async是异步函数，具备开启新的子线程的能力，所以GCD会开启之前相同的子线程A、B，在这两个子线程中同时运行耗时操作，所以程序会同时执行51、53、62、64行，最后等待耗时操作完成之后再执行54、65行。
 */
- (void)test1
{
    //获取全局的并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建队列组
    dispatch_group_t group = dispatch_group_create();
    
    NSLog(@"task one start");
    NSLog(@"task two start");
    
    dispatch_group_async(group, queue, ^{
        NSLog(@"线程1 = %@", [NSThread currentThread]);
        
        dispatch_async(queue, ^{
            NSLog(@"线程2 = %@", [NSThread currentThread]);
            
            sleep(3);  //这里线程睡眠3秒钟，模拟异步请求
            NSLog(@"task one finish");
        });
    });
    
    dispatch_group_async(group, queue, ^{
        NSLog(@"线程3 = %@", [NSThread currentThread]);
        
        dispatch_async(queue, ^{
            NSLog(@"线程4 = %@", [NSThread currentThread]);
            
            sleep(3);  //这里线程睡眠3秒钟，模拟异步请求
            NSLog(@"task two finish");
        });
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"线程5 = %@", [NSThread currentThread]);
        
        NSLog(@"all tasks finish");
    });
}

/**
 * dispatch_group_enter方法用于添加对应任务组中的未执行完毕的任务数，此方法执行一次，则未执行完毕的任务数加1，当未执行完毕任务数为0的时候，才会使dispatch_group_notify的block执行。dispatch_group_leave方法用于减少任务组中的未执行完毕的任务数，调用此方法来告知group组内任务何时才是真正的结束，此方法执行一次，则未执行完毕的任务数减1。dispatch_group_enter方法和dispatch_group_leave方法要成对使用，不然系统会认为这个任务没有执行完毕；
 * 以下的代码，通过dispatch_group_enter告知group，一个任务开始，未执行完毕任务数加1，在异步线程任务执行完毕时，通过dispatch_group_leave告知group，一个任务结束，未执行完毕任务数减1，当未执行完毕任务数为0的时候，这时group才认为组内任务都执行完毕了（这个和GCD的信号量的机制有些相似），这时候才会回调dispatch_group_notify中的block了；
 * 程序一开始的时候先执行82，83行，然后GCD把任务放到并发队列(queue)中，然后GCD再按照“先进先出，后进后出”的原则把任务再拿出来，因为dispatch_async方法是异步函数，具有创建新的子线程的能力，所以GCD再把任务放到新创建的子线程A、B中，程序再同时执行87，89，96，98行，等子线程中的耗时操作完成以后再执行90，99行，最后再执行91，100行，此时队列组中的未执行完毕任务数为0，所以才会执行dispatch_group_notify方法的block；
 * 在开发过程中一个页面可能会调用多个接口，应该等所有的接口都调用完以后再统一刷新主线程上的UI，而不是调用完一个接口刷新一次，这样会很耗费手机的性能。建议使用下面的方法，等所有接口都调用完成以后再做其他的操作。利用dispatch_group_leave方法来告知系统什么时候才是异步请求真正完成的时候。
 */
- (void)test2
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    NSLog(@"task one start");
    NSLog(@"task two start");
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"线程1 = %@", [NSThread currentThread]);
        
        sleep(3); //这里线程睡眠3秒钟，模拟异步请求
        NSLog(@"task one finish");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"线程2 = %@", [NSThread currentThread]);
        
        sleep(3); //这里线程睡眠3秒钟，模拟异步请求
        NSLog(@"task two finish");
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"线程3 = %@", [NSThread currentThread]);
        
        NSLog(@"all tasks finish");
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
