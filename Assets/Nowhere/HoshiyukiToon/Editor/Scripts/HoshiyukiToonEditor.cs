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
                MaterialProperty    lineColor;
                MaterialProperty    lineSize;
                
                MaterialProperty    cullMode;
                MaterialProperty    useStandardGI;

                bool            m_firstTimeApply    = true;
                MaterialEditor  m_materialEditor    = null;
                EditFlag        m_editFlag          = EditFlag.None;
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

                        GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
                        DoAlbedoArea(mtl);
                        m_materialEditor.TexturePropertySingleLine(Styles.rampText, rampMap, rampMap.textureValue!=null ? rampFactor : null);
                        m_materialEditor.TextureScaleOffsetProperty(albedoMap);
                        DoLineArea(mtl);

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

                    blendMode           = FindProperty("_Blend", props, false);
                    albedoMap           = FindProperty("_MainTex", props);
                    albedoColor         = FindProperty("_Color", props);
                    alphaCutoff         = FindProperty("_Cutoff", props, false);
                    rampMap             = FindProperty("_ToonTex", props);
                    rampFactor          = FindProperty("_ToonFactor", props);
                    lineColor           = FindProperty("_OutlineColor", props, false);
                    lineSize            = FindProperty("_OutlineSize", props, false);

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
                    SetupWithGIMode(mtl, mtl.GetFloat("_UseStandardGI")==1f);
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

                static void SetupWithGIMode(Material mtl, bool useStandardGI) {

                    if( useStandardGI )
                    {
                        mtl.EnableKeyword("NWH_TOON_STANDARDGI");
                    }
                    else{
                        mtl.DisableKeyword("NWH_TOON_STANDARDGI");
                    }
                }
			#endregion

			#region Methods
			#endregion
		#endregion
	}
}