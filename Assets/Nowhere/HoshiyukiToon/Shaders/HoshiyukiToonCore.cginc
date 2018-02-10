#ifndef NWH_HOSHIYUKI_TOON_CORE_INC
#define NWH_HOSHIYUKI_TOON_CORE_INC

/* includes */
#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityInstancing.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityStandardInput.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityGBuffer.cginc"
#include "UnityStandardBRDF.cginc"
#include "AutoLight.cginc"

#include "HoshiyukiToonLighting.cginc"


#ifdef _PARALLAXMAP
	#define IN_VIEWDIR4PARALLAX(i) normalizePerPixelNormal(half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w))
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) normalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
	#define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
#endif

#if UNITY_REQUIRE_FRAG_WORLDPOS
    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
        #define IN_WORLDPOS(i) half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w)
    #else
        #define IN_WORLDPOS(i) i.posWorld
    #endif
    #define IN_WORLDPOS_FWDADD(i) i.posWorld
#else
    #define IN_WORLDPOS(i) half3(0,0,0)
    #define IN_WORLDPOS_FWDADD(i) half3(0,0,0)
#endif


#define FRAGMENT_SETUP(x) FragmentCommonData x =\
	setupFragment(i.tex, i.eye, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i));




struct FragmentCommonData {
	half3 diffuse, specular;
	half alpha;
	half3 normalWorld, eye, posWorld;
};


/* Variable get */
/* end */


/* Functions */
	half3 normalizePerVertexNormal( float3 N ) {
	#if (SHADER_TARGET < 30)
		return normalize( N );
	#else
		return N;
	#endif
	}

	half3 normalizePerPixelNormal( half3 N ) {
		#if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
			return N;
		#else
			return normalize(N);
		#endif
	}

	half3 perPixelWorldNormal( float4 tex, half4 tangentToWorld[3] ) {

		half3 normalWorld;

	#ifdef _NORMALMAP
		half3 T = tangentToWorld[0].xyz;
		half3 B = tangentToWorld[1].xyz;
		half3 N = tangentToWorld[2].xyz;

		#if UNITY_TANGENT_ORTHONORMALIZE
			N = normalizePerPixelNormal( N );

			// ortho-normalize tangent
			T = normalize( T - N*dot( T, N ) );

			// recalculate binormal
			half3 newB = cross( N, T );
			B = newB * sign( dot( newB, B ) );
		#endif

		half3 NT = NormalInTangentSpace( tex );
		normalWorld = normalizePerPixelNormal( T*NT.x + B*NT.y + N*NT.z );
	#else
		normalWorld = normalize( tangentToWorld[2].xyz );
	#endif

		return normalWorld;
	}

	half3x3 createTangentToWorldPerVertex( half3 N, half3 T, half Tsign ) {

		half sign = Tsign * unity_WorldTransformParams.w;
		half3 B = cross( N, T )*sign;
		return half3x3(T, B, N);
	}

	UnityLight getMainLight() {
		UnityLight l;

		l.color = _LightColor0.rgb;
		l.dir = _WorldSpaceLightPos0.xyz;
		return l;
	}

	UnityLight getAdditiveLight(half3 dir, half att) {
		UnityLight l;

		l.color = _LightColor0.rgb;
		l.dir = dir;
		#ifndef USING_DIRECTIONAL_LIGHT
			l.dir = normalizePerPixelNormal( l.dir );
		#endif

		// shadow
		l.color *= att;
		return l;
	}

	inline half4 getVertexToonGIForward( VertexInput v, float posWorld , half3 NW ) {

		half4 result = 0;

		// Static lightmaps
		#ifdef LIGHTMAP_ON
			result.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			result.zw = 0;
		// Sample light probe for Dynamic objects only
		#elif UNITY_SHOULD_SAMPLE_SH
			// Approximated illumination from non-important point lights
			#ifdef VERTEXLIGHT_ON
				// <EXP>
				result.rgb = Shade4PointLights(
					/* position */unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					/* color */unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					/* etc */unity_4LightAtten0, posWorld, NW
				);
			#endif
				
			// SH Global illumintations
			#ifdef NWH_TOON_STANDARDGI
				result.rgb	= ShadeSHPerVertex( NW, result.rgb );
			#else
				// My SH Function
				result.rgb	= ShadeToonSHPerVertex( NW, result.rgb );
			#endif
		#endif


		#if DYNAMICLIGHTMAP_ON
			result.zw	= v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		#endif

		return result;
	}

	inline UnityGI getFragmentToonGI( FragmentCommonData s, half occlusion, half4 ambOrMap, half atten, UnityLight light, bool reflections ) {

		UnityGIInput d;
		d.light			= light;
		d.worldPos		= s.posWorld;
		d.worldViewDir	= -s.eye;
		d.atten			= atten;
		#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
			d.ambient		= 0;
			d.lightmapUV	= ambOrMap;
		#else
			d.ambient		= ambOrMap.rgb;
			d.lightmapUV	= 0;
		#endif

		d.probeHDR[0]	= unity_SpecCube0_HDR;
		d.probeHDR[1]	= unity_SpecCube1_HDR;
		#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
			d.boxMin[0]	= unity_SpecCube0_BoxMin;
		#endif
		#ifdef UNITY_SPECCUBE_BOX_PROJECTION
			d.boxMax[0]			= unity_SpecCube0_BoxMax;
			d.probePosition[0]	= unity_SpecCube0_ProbePosition;
			d.boxMax[1]			= unity_SpecCube1_BoxMax;
			d.boxMin[1]			= unity_SpecCube1_BoxMin;
			d.probePosition[1]	= unity_SpecCube1_ProbePosition;
		#endif

		#ifdef NWH_TOON_STANDARDGI
			#define GIFUNCTION UnityGlobalIllumination
		#else
			#define GIFUNCTION HoshiyukiToonGI
		#endif

		if (reflections)
		{
			Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup( 1.0, -s.eye, s.normalWorld, s.specular );

			return GIFUNCTION( d, occlusion, s.normalWorld, g );
		}
		else
		{
			return GIFUNCTION( d, occlusion, s.normalWorld );
		}

		#undef GIFUNCTION
	}

	inline FragmentCommonData setupFragment( inout float4 io_tex, half3 eye, half3 viewForParallax, half4 tangentToWorld[3], half3 posWorld ) {

		io_tex = Parallax( io_tex, viewForParallax );

		half alpha = Alpha( io_tex.xy );
		#ifdef _ALPHATEST_ON
			clip( alpha - _Cutoff );
		#endif

		FragmentCommonData o = (FragmentCommonData)0;
		o.diffuse		= Albedo(io_tex);
		o.normalWorld	= perPixelWorldNormal(io_tex, tangentToWorld);
		o.eye			= normalizePerPixelNormal( eye );
		o.posWorld		= posWorld;

		// TODO : premul alpha
		return o;
	}
/* end */



/* ForwardBase Functions */

	struct VertexOutFwdBase {
		UNITY_POSITION( pos );
		float4 tex : TEXCOORD0;
		half3 eye : TEXCOORD1;
		half4 tangentToWorldAndPackedData[3] : TEXCOORD2;
		half4 ambientOrLightmapUV : TEXCOORD5;
		UNITY_SHADOW_COORDS(6)
		UNITY_FOG_COORDS(7)

		#if UNITY_REQUIRE_FLAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
			float3 posWorld : TEXCOORD8;
		#endif

		UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
	};

	/** 頂点シェーダー(FowardBase).
	 *
	 */
	VertexOutFwdBase vertForwardBase( VertexInput v )
	{
		VertexOutFwdBase o;
		UNITY_INITIALIZE_OUTPUT( VertexOutFwdBase, o ); // Zeromemory

		// Setup for gpu instancing and stereo
		UNITY_SETUP_INSTANCE_ID( v );
		UNITY_TRANSFER_INSTANCE_ID( v, o );
	    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
			
		// World pos transform
		float4 posWorld = mul( unity_ObjectToWorld, v.vertex );
		#if UNITY_REQUIRE_FLAG_WORLDPOS
			#if UNITY_PACK_WORLDPOS_WITH_TANGENT
				o.tangentToWorldAndPackedData[0].w = posWorld.x;
				o.tangentToWorldAndPackedData[1].w = posWorld.y;
				o.tangentToWorldAndPackedData[2].w = posWorld.z;
			#else
				o.posWorld = posWorld.xyz;
			#endif
		#endif

		// Transforms
		o.pos = UnityObjectToClipPos( v.vertex );
		o.tex = TexCoords( v );
		o.eye = normalizePerVertexNormal( posWorld.xyz - _WorldSpaceCameraPos );

		// Transform Normal
		float3 normalWorld = UnityObjectToWorldNormal( v.normal );
		#ifdef _TANGENT_TO_WORLD
			float4		tangetWorld		= float4(UnityObjectToWorldDir( v.tangent.xyz ), v.tangent.w);
			float3x3	tangentToWorld	= CreateTangentToWorldPerVertex( normalWorld, tangentWorld.xyz, tangentWorld.w );
			
			o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
			o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
			o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
		#else
			o.tangentToWorldAndPackedData[0].xyz = 0;
			o.tangentToWorldAndPackedData[1].xyz = 0;
			o.tangentToWorldAndPackedData[2].xyz = normalWorld;
		#endif

		// Shadow receive
		UNITY_TRANSFER_SHADOW( o, v.uv1 );

		// Lightmap
		o.ambientOrLightmapUV = getVertexToonGIForward( v, posWorld, normalWorld );

		
		// Parallax mapping
		#ifdef _PARALLAXMAP
			TANGENT_SPACE_RORATION;
			half3 viewDirForParallax = mul( rotation, ObjSpaceViewDir( v.vertex ) );
			o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
			o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
			o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
		#endif
			
		UNITY_TRANSFER_FOG( o, o.pos );
		return o;
	}

	/** フラグメントシェーダー(FowardBase).
	 *
	 */
	half4 fragForwardBase( VertexOutFwdBase i ) : SV_Target{

		UNITY_APPLY_DITHER_CROSSFADE( i.position.xy );
		FRAGMENT_SETUP(s)

		UnityLight mainLight = getMainLight();
		UNITY_LIGHT_ATTENUATION( atten, i, s.posWorld );

		// Global illumination
		half occlusion = Occlusion( i.tex.xy );
		UnityGI gi = getFragmentToonGI( s, occlusion, i.ambientOrLightmapUV, atten, mainLight, false );

		// main light
		half4 c = NWH_HTS_Lighting( s.diffuse, s.specular, 0, 0, s.normalWorld, -s.eye, gi.light, gi.indirect );
		c.rgb += Emission( i.tex.xy );

		//c.rgb = gi.indirect.diffuse;

		return c;
	}
/* end */

#endif