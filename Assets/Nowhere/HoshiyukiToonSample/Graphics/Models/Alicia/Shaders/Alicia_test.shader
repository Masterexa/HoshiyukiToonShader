// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Alicia/Alicia_test" {
	Properties {
		//_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Diffuse(RGB)", 2D) = "white" {}
		_CelTex ("Cel(RGB)", 2D) = "white" {}
		_RimTex("RimTex", 2D) = "black"{}
		_ShadowColor("Shadow Color", Color) = (0,0,0,1)
		_SpColor("Specular Color", Color) = (0,0,0,1)
		_RimColor("Rim Color", Color) = (0,0,0,1)
		_Gross("Gross", range(0.0, 1)) = 0.1
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Width", float) = 0.05
	}
SubShader {

Tags
{
	"RenderType"="Opaque"  "Queue"="Geometry" "LightMode"="ForwardBase"
}

Pass{

	CGPROGRAM
	#pragma target 3.0
	#pragma multi_compile_fwdbase
	#pragma vertex vert
	#pragma fragment frag
	#include "AutoLight.cginc"
	#include "UnityCG.cginc"
		
	//half4 _Color;
	sampler2D _MainTex;
	sampler2D _CelTex;
	sampler2D _RimTex;
	half4 _ShadowColor;
	half4 _RimColor;
	half4 _SpColor;
	half _Depth;
	half _Gross;
	
	float4 _MainTex_ST;
	fixed4 _LightColor0;
		
	struct v2f{
		float4	pos : SV_POSITION;
		float2	uv : TEXCOORD0;
		float3	lightDir : TEXCOORD1;
		float3	viewDir : TEXCOORD2;
		float3  normal : TEXCOORD3;
		LIGHTING_COORDS (4,5) 
		float4  color : COLOR;
	};
	
	v2f vert(appdata_full v){
		v2f o;
		//v.color = _Color;
		o.color = v.color;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
		o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
		o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
		o.normal = v.normal;
		
		TRANSFER_VERTEX_TO_FRAGMENT( o );
		return o;
	}
	
	half4 frag (v2f i) : COLOR
	{
		//comment : NormalMap
		half3 norm = normalize(i.normal);
		
		//comment : diffuse
		half4 texcol = tex2D (_MainTex,i.uv);
		
		//comment : Light0
		float4 lightColor = _LightColor0 * _SpColor * 2;
		
		//comment : Speculer
		half3 hv = normalize(i.viewDir + i.lightDir);
		half lspec = dot(hv,norm);
		half4 p = pow(lspec, (1-_Gross) * 10);
		half4 specWeight = smoothstep(1 - _Gross,1 - _Gross + 0.01,p);
		
		//comment : harf lambert + vertexColor
		half2 toon = (dot( i.lightDir, norm) * 0.5 + 0.5);
		
		toon = clamp(toon,0,1);
		
		//comment : shadow
		half4 shadowcol = LIGHT_ATTENUATION( i );
		half4 celcol = max((tex2D(_CelTex, half2(toon)) * shadowcol),0);
		half4 cel = min(celcol + _ShadowColor, 1);
		
		//comment : rim	
		half rim = saturate(dot(i.viewDir,norm));
		half3 rimcol = tex2D (_RimTex, half2(rim,0)).rgb * _RimColor.rgb;
    	
    	//comment : color out
    	half4 outColor;
    	outColor.rgb = texcol.rgb * cel.rgb * (_LightColor0.rgb);
    	outColor.rgb += (lightColor * specWeight.rgb)  + rimcol.rgb;
    	clip(texcol.a - 0.5);
    	outColor.a = texcol.a;
    	
    	return outColor;
	}
	ENDCG
}
Pass{

	Cull Front
	Lighting Off

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"

	float4 _OutlineColor;
	float _OutlineWidth;  

	struct v2f {
		float4  pos : SV_POSITION;
		fixed2  uv : TEXCOORD0;
		float3  normal : TEXCOORD1;
	};

	v2f vert (appdata_full v) {
		v2f o;
		//v.color = _Color;
		o.pos = UnityObjectToClipPos(v.vertex);
    	float3 norm = mul (UNITY_MATRIX_MV,float4(v.normal,0));
    	float2 offset = TransformViewToProjection(norm.xyz);
		
	    o.pos.xy +=  _OutlineWidth/100 * offset;
	    o.pos.z += 0.0001 / o.pos.w;
		return o;
	}
	
	half4 frag(v2f i) : COLOR {

		return half4(_OutlineColor.rgb,1);
	}
	ENDCG
}

}
	FallBack "Transparent/Cutout/VertexLit"
}
