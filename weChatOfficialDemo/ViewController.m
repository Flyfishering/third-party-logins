//
//  ViewController.m
//  weChatOfficialDemo
//
//  Created by mac on 16/12/12.
//  Copyright © 2016年 mac. All rights reserved.
//

#define WX_App_ID       @"wx3d40739db8ea9f4f"
#define WX_App_Secret   @"7f2691147b0eec3d7421be18a3a27108"
#define WX_BASE_URL     @"https://api.weixin.qq.com/sns"


#import "ViewController.h"
#import "AFNetworking.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)weiChatLogin:(id)sender {
    [self weChatLogin];
}

-(void)weChatLogin {
    
//    方法一：只有手机安装了微信才能使用
//    if ([WXApi isWXAppInstalled]) {
//        SendAuthReq *req = [[SendAuthReq alloc] init];
//        //这里是按照官方文档的说明来的此处我要获取的是个人信息内容
//        req.scope = @"snsapi_userinfo";
//        req.state = @"";
//        //向微信终端发起SendAuthReq消息
//        [WXApi sendReq:req];
//    } else { 
//        NSLog(@"安装微信客户端");
//    }
    
//    方法二：手机没有安装微信也可以使用，推荐使用这个
    SendAuthReq *req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo";
    req.state = @"";
    [WXApi sendAuthReq:req viewController:self delegate:self];
}

#pragma mark - WXApiDelegate
-(void)onResp:(BaseResp *)resp{
    //判断是否是微信认证的处理结果
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *temp = (SendAuthResp *)resp;
        //如果你点击了取消，这里的temp.code 就是空值
        if (temp.code != NULL) {
            //此处判断下返回来的code值是否为错误码
            /*此处接口地址为微信官方提供，我们只需要将返回来的code值传入再配合appId和appSecret即可获取到accessToken，openId和refreshToken */
            //https://api.weixin.qq.com/sns  /oauth2/access_token
            NSString *accessUrlStr = [NSString stringWithFormat:@"%@/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", WX_BASE_URL, WX_App_ID, WX_App_Secret, temp.code];
            
           AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
            
            [manager GET:accessUrlStr parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [self p_successedWeiChatLogin:responseObject];
                NSLog(@"%@",responseObject);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [self p_failureWeiChatLogin:error];
            }];
        }
    }
}

#define WeiChat_accessToken     @"access_token"
#define WeiChat_openid          @"openid"
#define WeiChat_refreshToken    @"refresh_token"
#define WeiChat_unionid         @"unionid"
/**
 网络请求成功

 @param dic 网络请求数据
 */
- (void)p_successedWeiChatLogin:(NSDictionary *)dic{
    NSDictionary *returnObject = [NSDictionary dictionary];
    returnObject = dic;
    //成功返回
    //                {
    //                    "access_token" = "fdpTn5awALLnJ7g-RAjLjMT7DAFInXhbIjmLZzmrLea8jQtJm2VyEEIB3wlL_veLuqkg5zzCNKdvnV6gHXPo76ki0z4kiQ1CXA62SnneKZI";  接口调用凭证
    //                    "expires_in" = 7200;//接口调用凭证超时时间，单位（秒）
    //                    openid = ovMVmwh0TzOnVQX6oIbtMl2R5zXg;//授权用户唯一标识
    //                    "refresh_token" = "4GjXOOIAOBYuxO7wfjimyB1d_H6xLeCeUeng8bKDCzv5-N3yZSueJiq77_aAeO97eG0cUSLnz6UTkh9_j6l0tuS4Dlcs6c3ZC1xTmCUe0M0";//用户刷新access_token
    //                    scope = "snsapi_userinfo";//用户授权的作用域，使用逗号（,）分隔
    //                    unionid = oTlu3wJzgi6iVVb8txmzCkZwwYvU;//当且仅当该移动应用已获得该用户的userinfo授权时，才会出现该字段
    //                }
    
  
    
    NSString *accessToken = returnObject[WeiChat_accessToken];
    NSString *openid      = returnObject[WeiChat_openid];
    NSString *refreshToken      = returnObject[WeiChat_refreshToken];
    NSString *unionid      = returnObject[WeiChat_unionid];
    if (accessToken.length <=0) {
        return;
    }
    if (!openid||openid.length <=0 ) {
        return;
    }
    
    //    保存请求到的access_token，openid，refresh_token，unionid等
    [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:WeiChat_accessToken];
    [[NSUserDefaults standardUserDefaults] setObject:openid forKey:WeiChat_openid];
    [[NSUserDefaults standardUserDefaults] setObject:refreshToken forKey:WeiChat_refreshToken];
    [[NSUserDefaults standardUserDefaults] setObject:unionid forKey:WeiChat_unionid];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //注意下，access_token最好存到服务器（在项目中一定要考虑好安全性），我的demo就存到本地了
    
    //请求个人信息
    [self p_requestUserInfoDescriptionAccessToken:accessToken openId:openid];
}


/**
 网络请求错误

 @param error 错误信息
 */
- (void)p_failureWeiChatLogin:(NSError *)error{
    
    NSError *netErr = [[NSError alloc] init];
    netErr = error;
    
}

- (void)p_requestUserInfoDescriptionAccessToken:(NSString *)accessToken openId:(NSString *)openId{
    
    //使用微信官方提供的接口获取授权用户个人信息
    NSString *userUrlStr = [NSString stringWithFormat:@"%@/userinfo?access_token=%@&openid=%@", WX_BASE_URL, accessToken, openId];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    [manager GET:userUrlStr parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
    
//    [GameRequestTool getWithUrlString:userUrlStr success:^(id data) { NSDictionary *dict = [data objectFromJSONData];
//        DPFLog(@"dict -- %@", dict);
//        NSString *nickname = [dict objectForKey:@"nickname"];
//        if (nickname != NULL) {
//            LogInViewController *loginVC = [[LogInViewController alloc]init];
//            [self.window addSubview:loginVC.view];
//        } else {
//            DPFLog(@"登录失败、、、");
//        }
//    } failure:^(NSError *error) {
//        DPFLog(@"error -- %@", error);} showView:self.window];
//}
}


- (void)successedGetUserInfo:(NSDictionary *)returnObject{
//    {
//        city = Guangzhou;//城市
//        country = CN;//国家
//        headimgurl = "http://wx.qlogo.cn/mmopen/EFUxelibwGia7ia26dSqVHrLB6iaVAPxnov9v4PJ3YOacAFnNkENqnYumF7SHppPiaNxsaCZRic7gE8dvClxQwZeoibkWTHf1D6b94c/0";//头像
//        language = "zh_CN";//语言
//        nickname = "(=^_^=)";//昵称
//        openid = ovMVmwh0TzOnVQX6oIbtMl2R5zXg;
//        privilege =     (
//        );
//        province = Guangdong;//省市
//        sex = 1;//性别
//        unionid = oTlu3wJzgi6iVVb8txmzCkZwwYvU;
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
