using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using System;
using System.IO;
using UnityObject = UnityEngine.Object;

namespace HoshiyukiToonShaderEditor.RampUpgradeWizard{

#region Tree View Classes

    /// <summary>
    /// \~english   Class for building a file tree.
    /// \~japanese  ファイルツリーの組み立てを行うクラス.
    /// </summary>
    class FileTreeBuilder {

        #region Fields
            ScheduledMaterial[] materials { get; set; }

            Dictionary<string,TreeViewItem> m_directries = new Dictionary<string, TreeViewItem>();
            int m_counter=0;
        #endregion

        #region Methods
            public FileTreeBuilder() {
            }
        
            public void BuildTree(TreeViewItem root, ScheduledMaterial[] pathes) {

                this.materials = pathes;
                for(int i = 0; i<pathes.Length; i++)
                {
                    var it = pathes[i];
                    var item = CreateFileItem(i, it.path);
                    AddParent(it.path, item, root);
                }
                m_counter=0;
                m_directries.Clear();
                
            }
        #endregion

        #region Tree Methods
            void AddParent(string path, TreeViewItem child, TreeViewItem root) {

                string  dir     = Path.GetDirectoryName(path);
                if(string.IsNullOrEmpty(dir))
                {
                    root.AddChild(child);
                    return;
                }
                TreeViewItem    parent  = null;
                bool            isFound = m_directries.TryGetValue(dir, out parent);

                if(!isFound)
                {
                    parent = CreateDirectryItem(dir);
                    m_directries.Add(dir, parent);
                    AddParent(dir, parent, root);
                }
                parent.AddChild(child);
            }

            TreeViewItem CreateFileItem(int idx, string path)
            {
                return CreateItem(idx, path);
            }

            TreeViewItem CreateDirectryItem(string path)
            {
                return CreateItem(materials.Length + (m_counter++), path);
            }

            TreeViewItem CreateItem(int id, string path)
            {
                return new TreeViewItem(id, -1, Path.GetFileNameWithoutExtension(path));
            }
        #endregion
    }


    /// <summary>
    /// \~english   Tree view for material list in upgrader wizard.
    /// </summary>
    class MaterialTreeView : TreeView {
        
        #region GUI Resources
            static Texture2D    s_FolderIcon;
            static Texture2D    s_MaterialIcon;
            static GUIStyle     s_toggleMixed;
        #endregion

        /// <summary>
        /// \~english   Initialization of the class
        /// </summary>
        static MaterialTreeView() {
            s_FolderIcon    = EditorGUIUtility.FindTexture("Folder Icon");
            s_MaterialIcon  = EditorGUIUtility.FindTexture("Material Icon");
            s_toggleMixed   = new GUIStyle("ToggleMixed");
        }


        #region Instance
            #region Fields
                ScheduledMaterial[] m_materialPairs;
                public ScheduledMaterial[] allMaterials{
                    get { return m_materialPairs; }
                }

                public int materialCount {
                    get { return m_materialPairs.Length; }
                }

                public int scheduledMaterialCount {
                    get { return m_materialPairs.Count( (it)=>it.isScheduled ); }
                }
            #endregion

            #region Initialization Methods
                public MaterialTreeView(TreeViewState state) : base(state) {
                    showAlternatingRowBackgrounds = true;
                    this.showBorder = true;
                }

                protected override TreeViewItem BuildRoot() {
                    var root    = new TreeViewItem(-1, -1, "");
                    var buider  = new FileTreeBuilder();

                    buider.BuildTree(root, m_materialPairs);
                    SetupDepthsFromParentsAndChildren(root);
                    return root;
                }

                public void Reload(ScheduledMaterial[] pathes) {
                    m_materialPairs = pathes;
                    Reload();
                }
            #endregion

            #region GUI Events
                protected override void SelectionChanged(IList<int> selectedIds) {

                    base.SelectionChanged(selectedIds);
                }

                protected override void RowGUI(RowGUIArgs args) {

                    var ev = Event.current;
                    extraSpaceBeforeIconAndLabel = 36f; //18
                    

                    // Get aseet type is Folder or Material
                    var iconTex = (args.item.id<m_materialPairs.Length) ? s_MaterialIcon : s_FolderIcon;

                    Rect    toggleRc = args.rowRect,
                            iconRc;
                    toggleRc.x          += GetContentIndent(args.item);
                    toggleRc.width      = 16f;
                    iconRc              = toggleRc;
                    iconRc.x            += toggleRc.width;

                    if( (ev.type==EventType.MouseDown) )
                    {
                        if( (ev.button==1) && args.rowRect.Contains(ev.mousePosition) )
                        {
                            SelectionClick(args.item, true);
                            OnRightClickMenu(args);
                        }
                        else if( (ev.button==1) && toggleRc.Contains(ev.mousePosition) )
                        {
                            SelectionClick(args.item, false);
                        }
                    }
                    
                    DoToggle(toggleRc, args.item);


                    GUI.DrawTexture(iconRc, iconTex);
                    base.RowGUI(args);
                }
            #endregion

            #region GUI Methods
                void DoToggle(Rect rect, TreeViewItem item) {

                    var ret     = CheckScheduleRecursive(item);
                    var value   = ret==true || ret==null;

                    using(var chk = new EditorGUI.ChangeCheckScope())
                    {
                        value = EditorGUI.Toggle(rect, value, (ret==null) ? s_toggleMixed : EditorStyles.toggle);
                        if( chk.changed )
                        {
                            ChangeScheduleRecursive(item, value);
                        }
                    }
                }

                void OnRightClickMenu(RowGUIArgs args) {

                    var menu = new GenericMenu();

                    if(args.item.hasChildren)
                    {
                        menu.AddItem(new GUIContent("Open in Project"), false, (obj) =>
                        {
                            var item    = (TreeViewItem)obj;
                            var folder  = AssetDatabase.LoadAssetAtPath<UnityObject>( GetParentPath(item) );
                            EditorGUIUtility.PingObject(folder);
                        }, args.item);

                        menu.AddSeparator("");

                        // Expand All
                        menu.AddItem(new GUIContent("Expand All"), false, (obj) =>
                        {
                            SetExpandedRecursive((int)obj, true);
                        }
                        , args.item.id);

                        // Collapse All
                        menu.AddItem(new GUIContent("Collapse All"), false, (obj) =>
                        {
                            SetExpandedRecursive((int)obj, false);
                        }
                        , args.item.id);
                    }
                    else
                    {
                        menu.AddItem(new GUIContent("Open in Project"), false, (obj) =>
                        {
                            EditorGUIUtility.PingObject(m_materialPairs[(int)obj].material);
                        }, args.item.id);

                        menu.AddSeparator("");

                        menu.AddDisabledItem(new GUIContent("Expand All"));
                        menu.AddDisabledItem(new GUIContent("Collapse All"));
                    }

                    // Show right click menu
                    menu.ShowAsContext();
                }
            #endregion

            #region Tree Methods
                string GetParentPath(TreeViewItem item) {

                    var path = GetParentPathRecursive(item);
                    return path.Remove(path.Length-1);
                }

                string GetParentPathRecursive(TreeViewItem item){

                    if( item.parent==null )
                    {
                        return "";
                    }
                    return GetParentPathRecursive(item.parent) + item.displayName + '/';
                }

                bool? CheckScheduleRecursive(TreeViewItem item) {
                    if(item.hasChildren)
                    {
                        bool? firstVal = null;

                        foreach(var it in item.children)
                        {
                            var ret = CheckScheduleRecursive(it);

                            if( firstVal==null )
                            {
                                firstVal = ret;
                            }

                            // Check
                            if( ret==null || (ret!=firstVal) )
                            {
                                firstVal = null;
                                break;
                            }
                        }

                        return firstVal;
                    }

                    return m_materialPairs[item.id].isScheduled;
                }

                void ChangeScheduleRecursive(TreeViewItem item, bool b) {

                    if(item.hasChildren)
                    {
                        foreach(var it in item.children)
                        {
                            ChangeScheduleRecursive(it, b);
                        }
                    }
                    else
                    {
                        m_materialPairs[item.id].isScheduled = b;
                    }
                }
            #endregion
        #endregion
    }

    #endregion


    /// <summary>
    /// \~english    Upgrade wizard window
    /// </summary>
    class RampUpgradeWizard : EditorWindow{

        static RampUpgradeWizard main { get; set; }

        /// <summary>
        /// \~english   Create the window
        /// </summary>
        [MenuItem("HoshiyukiToon/Upgrade Point Ramp")]
        static void Init(){
            if( main==null )
            {
                main = CreateInstance<RampUpgradeWizard>();
            }
            main.ShowUtility();
        }

        /// <summary>
        /// \~english   Page of the setup wizard
        /// </summary>
        class Page {
            public delegate void GUIDelegate(Page page);
            
            #region Fields
                // Configations
                public string       title           { get; set; }
                public string       previousPage    { get; set; }
                public string       nextPage        { get; set; }
                public bool         confirmNext     { get; set; }
                public bool         canncelable     { get; set; }
                public GUIDelegate  onGUI           { get; set; }

                public bool isEndOfWizard {
                    get { return string.IsNullOrEmpty(nextPage); }
                }
            #endregion

            public Page() {
                    canncelable = true;
                }

            #region Events
                public void DrawGUI(RampUpgradeWizard wizard)
                {
                    wizard.DoHeaderLabel(new GUIContent(title));
                    EditorGUILayout.Space();
                    onGUI.Invoke(this);
                }

                public void DrawFooter(RampUpgradeWizard wizard)
                {
                    using(var footer = new GUILayout.AreaScope(new Rect(10f,wizard.position.height-30f, wizard.position.width-20f,30f),"")){
                    using(var bottom = new EditorGUILayout.HorizontalScope())
                    {
                        // Back button
                        using(var dis = new EditorGUI.DisabledScope(string.IsNullOrEmpty(this.previousPage)))
                        {
                            if( GUILayout.Button("Back", GUILayout.ExpandWidth(false)) )
                            {
                                wizard.GoPreviousPage();
                            }
                        }
                            
                        // Space between Back and Cancel
                        GUILayout.FlexibleSpace();


                        // Cancel button
                        if( this.canncelable )
                        {
                            if(GUILayout.Button("Cancel", GUILayout.ExpandWidth(false)))
                            {
                                if(wizard.DisplayDialog("Do you want to abort the setup?"))
                                {
                                    wizard.GoCanncelPage();
                                }
                            }
                        }

                        // Next & Finish button
                        {
                            var label = this.isEndOfWizard ? "Finish" : "Next";

                            if( GUILayout.Button(label, GUILayout.ExpandWidth(false)) )
                            {
                                if( this.confirmNext && wizard.DisplayDialog("You can not UNDO the operation.\nAre you sure you want to proceed?") )
                                {
                                    wizard.GoNextPage();
                                }
                                else if( !this.confirmNext )
                                {
                                    wizard.GoNextPage();
                                }
                            }
                        }
                    }}// End of footer area
                }
            #endregion
        }


        #region GUI Resources
            static RectOffset   s_padding = new RectOffset(20,20,10,40);
            static GUIStyle     s_headerLabelStyle;
            static GUIContent   s_refreshButtonContent;
            static GUIContent   s_titleContent;
        #endregion

        #region Page Names
            /*
             *  Those constants are use for identify the page.
             */
            static readonly string  SelectMaterialsPage     = "Start";
            static readonly string  OptionsPage             = "Options";
            static readonly string  ProcessingPage          = "Processing";
            static readonly string  FinishPage              = "Finish";
            static readonly string  CanncelPage             = "Canncelled";
            static readonly string  ExitSentinelPage        = "EXIT";
        #endregion

        /// <summary>
        /// \~english   Initialization of the class
        /// </summary>
        static RampUpgradeWizard() {
            s_refreshButtonContent      = new GUIContent("Refresh", EditorGUIUtility.FindTexture("RotateTool"), "");
            s_titleContent              = new GUIContent("Upgrade Point Ramp");

            s_headerLabelStyle          = new GUIStyle(EditorStyles.largeLabel);
            s_headerLabelStyle.font     = EditorStyles.boldFont;
            s_headerLabelStyle.fontSize = 18;

            var normal                  = s_headerLabelStyle.normal;
            normal.textColor            = new Color(0.4f, 0.4f, 0.4f);
            s_headerLabelStyle.normal   = normal;
        }



        #region Instance
            #region UI&Page Fields
                // Page Statements
                Dictionary<string,Page>    m_pages = new Dictionary<string, Page>();
                Page    m_currentPage;
                string  m_pageQuery;

                // UI Elements
                MaterialTreeView    m_treeView;
                TreeViewState       m_treeViewState;
                SearchField         m_searchField;
                
                // Layout 
                Rect PageRect {
                    get {
                        return new Rect(
                            s_padding.left,
                            s_padding.top,
                            position.width - s_padding.right - s_padding.left,
                            position.height - s_padding.top - s_padding.bottom
                        );
                    }
                }
            #endregion

            #region Upgrade Configation Fields
                bool        m_setupIsNotNeeded      = false; 
                Texture2D   m_pointRampTex          = null;
                bool        m_isCopyFromDirection   = true;
            #endregion

            #region EditorWindow Events
                ///<summary>
                ///\~english   Use this for initialization.
                ///</summary>
                void OnEnable() {
                    // Apply Title
                    this.titleContent   = s_titleContent;
                    {
                        var sz          = this.position;
                        sz.size         = new Vector2(600f,400f);
                        this.position   = sz;
                    }


                    // Init TreeView
                    if( m_treeViewState==null )
                    {
                        m_treeViewState = new TreeViewState();
                    }
                    m_treeView = new MaterialTreeView(m_treeViewState);


                    // Initialize SearchField
                    m_searchField = new SearchField();
                    m_searchField.downOrUpArrowKeyPressed += m_treeView.SetFocusAndEnsureSelectedItem;


                    // Register pages
					m_pages.Add(SelectMaterialsPage,    new Page {title="Select Materials",    onGUI=OnMaterialListPage,   nextPage=OptionsPage});
                    m_pages.Add(OptionsPage,            new Page {title="Options",             onGUI=OnOptionPage,         nextPage=ProcessingPage, previousPage=SelectMaterialsPage, confirmNext=true});
                    m_pages.Add(ProcessingPage,         new Page {title="Processing",          onGUI=OnProcessingPage,     nextPage=FinishPage});
                    m_pages.Add(FinishPage,             new Page {title="Finished",            onGUI=OnDonePage, canncelable=false});
                    m_pages.Add(CanncelPage,            new Page {title="Canncelled",          onGUI=OnCanncelPage, canncelable=false});

                    GoPage( SelectMaterialsPage );
                    RefreshMaterialList();
                }

                ///<summary>
                ///\~english   Use this for draw window.
                ///</summary>
                void OnGUI(){
                    
                    // Process of page query
                    if( Event.current.type==EventType.Layout )
                    {
                        if( !string.IsNullOrEmpty(m_pageQuery) )
                        {
                            // Close the window
                            if( m_pageQuery==ExitSentinelPage )
                            {
                                this.Close();
                                return;
                            }
                            // Go to other page
                            else {
                                m_currentPage = m_pages[m_pageQuery];
                            }
                            m_pageQuery = null;
                        }
                    }
                    
                    
                    // Draw a Page
                    if( m_currentPage!=null )
                    {
                        // Draw GUI
                        using(var scr = new GUILayout.AreaScope(this.PageRect))
                        {
                            m_currentPage.DrawGUI(this);
                        }
                        m_currentPage.DrawFooter(this);
                    }
                }
			#endregion

			#region Page Drawing Callbacks
                void OnMaterialListPage(Page page) {

                    // Page setting
                    page.nextPage = (m_treeView.scheduledMaterialCount!=0) ? OptionsPage : null;
                    
            
                    // Draw Search field
                    var rc = GUILayoutUtility.GetRect(0,100f,0,20);
                    m_treeView.searchString = m_searchField.OnGUI(rc, m_treeView.searchString);

                    // Draw Tree view
                    rc = GUILayoutUtility.GetRect(0, 100f, 0, 300);
                    m_treeView.OnGUI(rc);        

                    // Refresh button
                    if( GUILayout.Button(s_refreshButtonContent, GUILayout.ExpandWidth(false)) )
                    {
                        RefreshMaterialList();
                    }

                    // Display num
                    GUILayout.Label(string.Format("Selected {0} of {1}.", m_treeView.scheduledMaterialCount, m_treeView.materialCount));
                }

                void OnOptionPage(Page page) {
                    
                    // Draw options
                    m_isCopyFromDirection   = GUILayout.Toggle(m_isCopyFromDirection, "Copy from Directional", EditorStyles.radioButton);
                    m_isCopyFromDirection   = !GUILayout.Toggle(!m_isCopyFromDirection, "Apply Single Texture", EditorStyles.radioButton);

                    // Draw texture setting
                    EditorGUI.indentLevel++;
                    EditorGUI.BeginDisabledGroup(m_isCopyFromDirection);
                    using(var box = new GUILayout.VerticalScope(EditorStyles.helpBox))
                    {
                        m_pointRampTex = (Texture2D)EditorGUILayout.ObjectField("Point Light Ramp", m_pointRampTex, typeof(Texture2D), false);
                    }
                    EditorGUI.EndDisabledGroup();
                    EditorGUI.indentLevel--;
                }

                void OnProcessingPage(Page page) {
                    
                    if( Event.current.type!=EventType.Repaint )
                    {
                        var options = RampUpgradeOptions.Asynchronously
                            | (m_isCopyFromDirection ? RampUpgradeOptions.CopyFromDirectional : RampUpgradeOptions.ApplySingleTexture)
                        ;

                        RampUpgrader.UpgradeMaterials(m_treeView.allMaterials, options, m_pointRampTex);
                        GoNextPage();
                    }
                }

                void OnDonePage(Page page) {
                    GUILayout.Label(  this.m_setupIsNotNeeded ? "Setup is not needed." : "Setup succeeded!");
                }

                void OnCanncelPage(Page page) {
                    GUILayout.Label("Setup is canncelled.");
                }
			#endregion

			#region Page Accessing Methods
                void GoPage(string page)
                {
                    m_pageQuery = string.IsNullOrEmpty(page) ? ExitSentinelPage : page;
                }

                void GoCanncelPage() {
                    GoPage(CanncelPage);
                }

                void GoNextPage() {
                    GoPage( m_currentPage.nextPage );
                }

                void GoPreviousPage() {
                    GoPage( m_currentPage.previousPage );
                }
            #endregion

            #region Misc Methods
                void DoHeaderLabel(GUIContent content) {
                    var rc  = GUILayoutUtility.GetRect(100f, s_headerLabelStyle.CalcHeight(content, this.PageRect.width));
                    GUI.Label(rc, content, s_headerLabelStyle);
                    EditorGUILayout.Space();
                }

                bool DisplayDialog(string message)
                {
                    return EditorUtility.DisplayDialog("Infomation", message, "OK", "Canncel");
                }

                void RefreshMaterialList() {
                    EditorUtility.DisplayProgressBar("Info", "Searching Materials", 1f);
                    {
                        ScheduledMaterial[] pairs;
                        RampUpgrader.FindUnupdatedMaterials(out pairs);
                        if( pairs.Length==0 )
                        {
                            m_setupIsNotNeeded = true;
                            GoPage(FinishPage);
                        }
                        else {
                            m_treeView.Reload( pairs );
                            m_treeView.ExpandAll();
                        }
                    }
                    EditorUtility.ClearProgressBar();
                }


			#endregion
		#endregion
	}
}