# hcdump

> [!NOTE]
> 撰写本文时卡通游戏启动器的版本为 `1.0.5.88`。

> [!CAUTION]
> 对商业软件进行逆向工程违反用户协议和法律法规，由此造成的一切后果由行为人自行承担。继续阅读本文或使用仓库中的其他资源，即视为您已知悉并认可该警告。

## 背景

某个卡通游戏启动器使用 Qt + 网页混合架构开发，其程序目录中含有一个 `AES-256-CBC` 加密的配置文件 `app.conf.dat`，和一个含有网页文件的加密 ZIP 压缩包 `feapp.dat`。这个仓库提供了一种读取和验证 `app.conf.dat` 文件的方法，其中包含 `feapp.dat` 的密码。

## `app.conf.dat` 文件结构

| 256 字节                 | 16 字节 | 剩余部分 |
| ------------------------ | ------- | -------- |
| `PKCS1v15(SHA-256)` 签名 | AES IV  | AES 密文 |

其中签名是对文件中除去签名部分的内容生成的。

## 获取公钥和密钥

他们可以通过对启动器进行逆向工程获取，方法较为简单。

公钥用于验证签名，可以忽略，在启动器中以 2048 位 RSA PEM 格式公钥的形式存在，大概长下面给出的样子。找到后保存为单独的文本文件。

```pem
-----BEGIN PUBLIC KEY-----
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxx
-----END PUBLIC KEY-----
```

密钥用于 AES 解密，在启动器中以 Base64 的形式存在。如果你使用仓库中提供的脚本或 `openssl` 命令用于后续的 AES 解密，需要将这个密钥转换为 HEX 格式。下面给出部分可行的方法。

- `base64 -d | hexdump -v -e '/1 "%02x"'`
- CyberChef：[带有配方的连接](https://gchq.github.io/CyberChef/#recipe=From_Base64('A-Za-z0-9%2B/%3D',true,true)To_Hex('None',0))

## 使用一键脚本

仓库中提供了一键脚本 `hcdump.bash`，可以自动验证和解密 `app.conf.dat` 文件并输出到标准输出。如果系统上安装了 `jq`，可以直接使用管道以格式化 JSON 输出。

```shell
./hcdump.bash -k xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -v publickey.pem app.conf.dat | jq
```

## JSON 结构

如果你懒得去得到密钥和相关文件，只是好奇文件内容，可以直接阅读以下 TypeScript 接口定义。

```typescript
interface AppConf {
    _meta_ver: string
    App: {
        Region: string
        Language: string
        Company: string
        Product: string
        Standalone: boolean
        Channel: string
        SubChannel: string
        LauncherId: string
        CPS: string
        UAPC: string
        PrimaryGame: string
        ClientEnv: string
        ClientPreview: boolean
        EnableBetaLogin: boolean
        WebApiBaseUrl: string
    }
    FE: {
        BridgeName: string
        PackageKey: string
    }
    Launcher: {
        LogDebugMode: boolean
        PlatApp: string
        Win7PatchUrl: string
        Win7PatchMd5: string
        Win7PatchEnable: boolean
    }
    ABTest: {
        Url: string
    }
    Box: {
        Url: string
    }
    H5Log: {
        Url: string
    }
    DataUpload: {
        Url: string
    }
    APM: {
        AppId: string
        AppKey: string
    }
    Updater: {
        AppId: string
        AppKey: string
        ReportUrl: string
    }
    Epic: {
        EnablePay: boolean
        ProductId: string
        SandboxId: string
        DeploymentId: string
        CredentialsId: string
        CredentialsSecret: string
    }
}
```
