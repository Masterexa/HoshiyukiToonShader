# Hoshiyuki Toon Shader
 Hoshiyuki Toon Shaderは、グローバルイルミネーションやHDRレンダリングに特化したUnity向けのトゥーンシェーダーです。
(このリポジトリは開発中で、仕様変更によって過去のバージョンとの互換性が失われる場合があります。あらかじめご了承ください)

 A toon shader system for Unity.

# Requirement
 Unity 2017.1.0 later

# Installation
1. Clone or DownloadのDownload ZIPからリポジトリをダウンロードするか、HoshiyukiToonShader.unitypackageを直接ダウンロードします。
2. ダウンロードしたHoshiyukiToonshader.unitypackageを、利用したいプロジェクト上でインポートします。[アセットパッケージのインポート方法はこちら。](https://docs.unity3d.com/jp/530/Manual/AssetPackages.html)
3. 利用したいマテリアルを選び、ShaderをHoshiyukiToonカテゴリの目的に応じたものに変更してください。 
 
# Material Properties

## Lit
|プロパティ名|型|変数名|説明|
|:--|:--|:--|:--|
|Rendering Mode|-|-|レンダリングモード。レンダリングの種類を指定します。|
|Albedo|Color|\_Color|マテリアルの基本色。テクスチャを使用する場合、それらの色と掛け合わされます。|
|Albedo (テクスチャ)|Texture2D|\_MainTex|マテリアルの基本テクスチャ。|
|Cutoff|Float|\_Cutoff|Rendering ModeがCutoffのときのみ有効。そのピクセルのAlbedoのアルファ値がここで設定した値未満のとき、そのピクセルは破棄されます。半透明を使用せずにポリゴンに穴を開けたいときに有効です。|
|Occlusion(テクスチャ)|Texture2D|\_OcclusionMap|オクルージョンマップ。グローバルイルミネーションの影響の強さを設定します。|
|Occlusion(スライダ)|Float|\_OcclusionStrength|オクルージョンマップの影響の強さ。|
|Emission|Color(HDR)|\_EmissionColor|マテリアルの発光色。テクスチャを使用する場合、それらの色と掛け合わされます。|
|Emission(テクスチャ)|Texture2D|\_EmissionMap|マテリアルの発光テクスチャ。|

## Lit(Ramp)
|プロパティ名|型|変数名|説明|
|:--|:--|:--|:--|
|Ramp(テクスチャ)|Texture2D|\_ToonTex|マテリアルの陰影に使用するグラデーションのテクスチャ。テクスチャのX座標は法線と光源ベクトルの内積(-1から1まで)に対応し、テクスチャの明るさはその積の反射率に対応します。|
|Ramp(スライダ)|Float|\_ToonFactor|マテリアルの陰影の強さ。|

## Outline
|プロパティ名|型|変数名|説明|
|:--|:--|:--|:--|
|Color|Color|\_OutlineColor|アウトラインの色。|
|Size|Float|\_OutlineSize|アウトラインの太さ。|

## Options
|プロパティ名|型|変数名|説明|
|:--|:--|:--|:--|
|Cull Mode|Float(UnityEngine.Rendering.CullMode)|\_Cull|カリングモード。|
|Use Standard GI|-|-|このオプションが有効なとき、マテリアルは標準的な方法でグローバルイルミネーションの明るさを求めます。|
