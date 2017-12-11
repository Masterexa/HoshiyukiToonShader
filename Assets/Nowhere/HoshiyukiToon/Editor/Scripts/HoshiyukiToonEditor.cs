using System.Collections;
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;


namespace NowhereUnityEditor.Rendering{

	///<summary>シェーダーのカスタムエディタ</summary>
	///<remarks>
	///
	///</remarks>
	public class HoshiyukiToonEditor : ShaderGUI{

        #region Typedefs
            enum BlendMode {
                Opaque,
                Cutoff
            }

            [System.Flags]
            enum EditFlag {
                None,
                Lit = 0x1,
                Line = 0x2,
                ModeEditable = 0x4,
            }

            static class Styles {
                public static GUIContent renderingMode  = new GUIContent("Rendering Mode", "レンダリングモード");
                public static GUIContent albedoText     = new GUIContent("Albedo", "反射率");
                public static GUIContent alphaCutoffText= new GUIContent("Alpha Cutoff", "しきい値");
                public static GUIContent rampText       = new GUIContent("Ramp", "陰影の設定");

                public static GUIContent occlusionText  = new GUIContent("Occlusion", "遮蔽マップの設定");
                public static GUIContent emissionText   = new GUIContent("Emission", "発光の設定");

                public static GUIContent lineSizeText   = new GUIContent("Size", "アウトラインの太さ(スクリーン空間)");
                public static GUIContent lineColorText  = new GUIContent("Color", "アウトラインの色(GIの影響を受ける)");

                public static GUIContent standardGIText                 = new GUIContent("Use Standard GI", "通常の方法でGIを受け取る");
                public static GUIContent cullModeText                   = new GUIContent("Cull Mode", "カリングモード");

                public static string primaryMapsText        = "Main Maps";
                public static string lineSettingsText       = "Outline";
                public static string advancedText           = "Advanced Options";
                public static readonly string[] blendNames  = Enum.GetNames(typeof(BlendMode));
            }
        #endregion

        #region Instance
            #region Fields
                MaterialProperty    blendMode;
                MaterialProperty    albedoColor;
                MaterialProperty    albedoMap;
                MaterialProperty    alphaCutoff;
                MaterialProperty    rampMap;
                MaterialProperty    rampFactor;
                MaterialProperty    occlusionFactor;
                MaterialProperty    occlusionMap;
                MaterialProperty    emissionColor;
                MaterialProperty    emissionMap;

                MaterialProperty    lineColor;
                MaterialProperty    lineSize;
                
                MaterialProperty    cullMode;
                MaterialProperty    useStandardGI;

                bool                    m_firstTimeApply    = true;
                MaterialEditor          m_materialEditor    = null;
                EditFlag                m_editFlag          = EditFlag.None;
                ColorPickerHDRConfig    m_hdrPickerConfig   = new ColorPickerHDRConfig(0f, 99f, 1f/99f, 3f);
            #endregion

            #region Properties
            #endregion

            #region Events
                public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props) {
                    FindProperties(props);
                    m_materialEditor    = materialEditor;
                    var mtl             = materialEditor.target as Material;

                    if( m_firstTimeApply )
                    {
                        MaterialChanged(mtl);
                        m_firstTimeApply = false;
                    }
                    ShaderPropertiesGUI(mtl);
                }

                void ShaderPropertiesGUI(Material mtl) {

                    EditorGUIUtility.labelWidth = 0f;
                    
                    EditorGUI.BeginChangeCheck();
                    {
                        EditorGUILayout.HelpBox("キャラクターは、陰影なし・シャドウキャスティングなしがおすすめです。", MessageType.Info);
                        BlendModeProp();

                        // Base Color Area
                        GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
                        DoAlbedoArea(mtl);
                        m_materialEditor.TexturePropertySingleLine(Styles.rampText, rampMap, (rampMap.textureValue!=null) ? rampFactor : null);
                        m_materialEditor.TexturePropertySingleLine(Styles.occlusionText, occlusionMap, (occlusionMap.textureValue!=null) ? occlusionFactor : null);
                        DoEmissionArea(mtl);
                        m_materialEditor.TextureScaleOffsetProperty(albedoMap);

                        // Outline Area
                        DoLineArea(mtl);

                        // Options Area
                        EditorGUILayout.Space();
                        GUILayout.Label(Styles.advancedText, EditorStyles.boldLabel);
                        m_materialEditor.ShaderProperty(cullMode, Styles.cullModeText);
                        m_materialEditor.ShaderProperty(useStandardGI, Styles.standardGIText);
                    }
                    if( EditorGUI.EndChangeCheck() )
                    {
                        foreach(var it in albedoColor.targets)
                            MaterialChanged((Material)it);
                    }
                }
            #endregion

            #region Pipeline
                void BlendModeProp() {
                    if( (m_editFlag&EditFlag.ModeEditable)==0 )
                    {
                        return;
                    }

                    EditorGUI.showMixedValue = blendMode.hasMixedValue;
                    var mode = (BlendMode)blendMode.floatValue;

                    EditorGUI.BeginChangeCheck();
                    {
                        mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode.text, (int)mode, Styles.blendNames);
                    }
                    if( EditorGUI.EndChangeCheck() )
                    {
                        m_materialEditor.RegisterPropertyChangeUndo("Rendering mode");
                        blendMode.floatValue = (float)mode;
                    }

                    EditorGUI.showMixedValue = false;
                }

                void DoAlbedoArea(Material mtl) {

                    m_materialEditor.TexturePropertySingleLine(Styles.albedoText, albedoMap, albedoColor);
                    if( ((m_editFlag&EditFlag.ModeEditable)!=0) && (BlendMode)mtl.GetFloat("_Blend")==BlendMode.Cutoff )
                    {
                        m_materialEditor.ShaderProperty(alphaCutoff, Styles.alphaCutoffText, MaterialEditor.kMiniTextureFieldLabelIndentLevel+1);
                    }
                }

                void DoEmissionArea(Material mtl) {

                    bool showHelp       = !HasValidEmissiveKeyword(mtl);
                    bool hadEmissionTex = emissionMap.textureValue != null;

                    // Texture and HDR color controls
                    m_materialEditor.TexturePropertyWithHDRColor(Styles.emissionText, emissionMap, emissionColor, m_hdrPickerConfig, false);
                    
                    float brightness = emissionColor.colorValue.maxColorComponent;
                    if( emissionMap.textureValue!=null && !hadEmissionTex && (brightness<=0) )
                    {
                        emissionColor.colorValue = Color.white;
                    }

                    // Emission for GI ?
                    m_materialEditor.LightmapEmissionProperty(MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
                }

                void DoLineArea(Material mtl) {
                    if( (m_editFlag&EditFlag.Line)!=0 )
                    {
                        EditorGUILayout.Space();
                        GUILayout.Label(Styles.lineSettingsText, EditorStyles.boldLabel);

                        m_materialEditor.ShaderProperty(lineColor, Styles.lineColorText);
                        m_materialEditor.ShaderProperty(lineSize, Styles.lineSizeText);    
                    }
                }

                void FindProperties(MaterialProperty[] props) {
                    
                    m_editFlag = EditFlag.None;

                    // Lit
                    blendMode           = FindProperty("_Blend", props, false);
                    albedoMap           = FindProperty("_MainTex", props);
                    albedoColor         = FindProperty("_Color", props);
                    alphaCutoff         = FindProperty("_Cutoff", props, false);
                    rampMap             = FindProperty("_ToonTex", props);
                    rampFactor          = FindProperty("_ToonFactor", props);
                    occlusionFactor     = FindProperty("_OcclusionStrength", props);
                    occlusionMap        = FindProperty("_OcclusionMap", props);
                    emissionColor       = FindProperty("_EmissionColor", props);
                    emissionMap         = FindProperty("_EmissionMap", props);
                    // Outline
                    lineColor           = FindProperty("_OutlineColor", props, false);
                    lineSize            = FindProperty("_OutlineSize", props, false);
                    // Option
                    cullMode                = FindProperty("_Cull", props);
                    useStandardGI           = FindProperty("_UseStandardGI", props);

                    if( blendMode!=null && alphaCutoff!=null )
                    {
                        m_editFlag |= EditFlag.ModeEditable;
                    }
                    if(lineColor!=null && lineSize!=null)
                    {
                        m_editFlag |= EditFlag.Line;
                    }
                    m_editFlag |= EditFlag.Lit;
                }

                void MaterialChanged(Material mtl) {

                    var bl = (m_editFlag&EditFlag.ModeEditable)!=0 ? (BlendMode)mtl.GetFloat("_Blend") : BlendMode.Opaque;
                    
                    SetupMaterialWithBlendMode(mtl, bl);
                    SetMaterialKeywords(mtl);
                }

                static void SetupMaterialWithBlendMode(Material mtl, BlendMode mode) {

                    switch(mode)
                    {
                        case BlendMode.Opaque:
                            mtl.DisableKeyword("NWH_TOON_CUTOUT");
                            break;
                        case BlendMode.Cutoff:
                            mtl.EnableKeyword("NWH_TOON_CUTOUT");
                            break;
                        default:
                            break;
                    }
                }

                static void SetMaterialKeywords(Material mtl) {

                    // Emission
                    bool shouldEmissionBeEnabled = ShouldEmissionBeEnabled(mtl, mtl.GetColor("_EmissionColor"));
                    SetKeyword(mtl, "_EMISSION", shouldEmissionBeEnabled);
                    // GI Mode
                    SetKeyword(mtl, "NWH_TOON_STANDARDGI", mtl.GetFloat("_UseStandardGI")==1f);

                    // Lightmap emissive
                    var flags = mtl.globalIlluminationFlags;
                    if( 0 != (flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) )
                    {
                        flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                        if( !shouldEmissionBeEnabled )
                        {
                            flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                        }
                        mtl.globalIlluminationFlags = flags;
                    }
                }
			#endregion

			#region Methods
                static bool ShouldEmissionBeEnabled(Material mtl, Color col) 
                {
                    bool realtimeEmission = 0 != (mtl.globalIlluminationFlags & MaterialGlobalIlluminationFlags.RealtimeEmissive);
                    return (col.maxColorComponent > 0.1f/255f) || realtimeEmission;
                }

                bool HasValidEmissiveKeyword(Material mtl) {
                    // See StandardShaderGUI.cs
                    bool hasEmissionKeyword = mtl.IsKeywordEnabled("_EMISSION");
                    return !( !hasEmissionKeyword && ShouldEmissionBeEnabled(mtl,emissionColor.colorValue) );
                }

                static void SetKeyword(Material mtl, string keyword, bool enabled) {

                    if(enabled)
                    {
                        mtl.EnableKeyword(keyword);
                    }
                    else
                    {
                        mtl.DisableKeyword(keyword);
                    }
                }
            #endregion
        #endregion
    }
}