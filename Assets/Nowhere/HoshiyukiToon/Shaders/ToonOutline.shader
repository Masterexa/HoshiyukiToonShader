/** アウトラインシェーダー.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/Outline"
{
	Properties
	{
		_OutlineColor	("Outline Color", Color) = (.0,.0,.0,1)
		_OutlineSize	("Outline Width", Range(.001,.03)) = .002
	}
	SubShader
	{
		Tags {"RenderType"="Transparent" "LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "Always" "Queue"="Transparent"}
			Cull Front
			ZWrite On
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				//#pragma multi_compile_fwdbase
				#pragma multi_compile_fog	// make fog work
				#include "HoshiyukiToonCommon.cginc"
				#include "HoshiyukiToonOutline.cginc"

				/* --- Uniforms --- */
					uniform float	_OutlineSize;
					uniform fixed4	_OutlineColor;
				/* end */


				/* --- Typedef --- */
					/** 頂点入力.
					 */
					struct appdata
					{
						float4 vertex	: POSITION;
						float3 normal	: NORMAL;
					};

					/** ピクセルシェーダー入力.
					 */
					struct v2f
					{
						UNITY_FOG_COORDS(2)
						float4	vertex		: SV_POSITION;
						fixed4	color		: COLOR;
						half3	ambient		: TEXCOORD0;
						float3	worldPos	: TEXCOORD1;
					};
				/* end */

				/* --- Shader Functions --- */
					/** 頂点シェーダー.
					 *
					 */
					v2f vert (appdata v)
					{
						v2f o;
						float3	N = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, float4(v.normal, 0)));

						// transformations
						o.worldPos	= mul(unity_ObjectToWorld, v.vertex).xyz;
						o.vertex	= UnityObjectToClipPos(v.vertex);
						o.color		= _OutlineColor;

						// expand vertex
						o.vertex = HTS_expandVertexOutline(_OutlineSize, TransformViewToProjection(N), o.vertex);

						// GI Calclation
						o.ambient = HTS_calculateVertexOutlineGI();


						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}
			
					/** フラグメントシェーダー.
					 *
					 */
					fixed4 frag (v2f i) : SV_Target
					{
						// sample the texture
						half4 col	= i.color;
						col.rgb		*= HTS_calculatePixelOutlineGI(i.ambient, i.worldPos);

						// apply fog
						UNITY_APPLY_FOG(i.fogCoord, col);
						return col;
					}
				/* end */
			ENDCG
		}
	}
}
