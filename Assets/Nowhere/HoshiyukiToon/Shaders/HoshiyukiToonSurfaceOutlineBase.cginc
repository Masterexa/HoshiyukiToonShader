#ifndef NWH_HTS_SURFACE_OUTLINE_BASE_INC
#define NWH_HTS_SURFACE_OUTLINE_BASE_INC

/* includes */
#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonOutline.cginc>

/* properties */
uniform float	_OutlineSize;
uniform fixed4	_OutlineColor;
uniform	fixed	_OutlineCull;

fixed		_Cutoff;
sampler2D	_MainTex;
fixed4		_Color;




/* typedefs */
	/** ピクセルシェーダー入力.
	 */
	struct v2f {
		UNITY_FOG_COORDS(3)
		float4	vertex		: SV_POSITION;
		fixed4	color : COLOR;
		float2	texcoord	: TEXCOORD0;
		half3	ambient		: TEXCOORD1;
		float3	worldPos	: TEXCOORD2;
	};




/* Functions */
	inline void clipMask(float2 texcoord)
	{
		#ifdef NWH_TOON_CUTOUT
			fixed a = tex2D(_MainTex, texcoord).a * _Color.a;
			clip(a - _Cutoff);
		#endif
	}




/* Shader kernels */
	/** 頂点シェーダー.
	 *
	 */
	v2f vertOutlineBase (appdata_full v)
	{
		v2f o;
						
		fixed isBackCull = step(0.1, abs(1-_OutlineCull));

		o.vertex	= v.vertex;
		o.texcoord	= v.texcoord.xy;
		o.color		= _OutlineColor;
		HTS_vertexOutlineOperation(_OutlineSize, isBackCull, v.normal, /*inout*/o.vertex, /*out*/o.ambient, /*out*/o.worldPos);
						

		UNITY_TRANSFER_FOG(o,o.vertex);
		return o;
	}
			
	/** フラグメントシェーダー.
	 *
	 */
	fixed4 fragOutlineBase (v2f i) : SV_Target
	{
		clipMask(i.texcoord);

		// Apply color and GI
		half4 col;
		HTS_fragmentOutlineOperation(i.color, i.worldPos, i.ambient, /*out*/col);

		// Apply fog
		UNITY_APPLY_FOG(i.fogCoord, col);
		return col;
	}
/* end */

#endif