import AppKit
import ScriptingBridge

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    var isRunning: Bool { get }
}

// MARK: DEVONthinkSaveOptions
@objc public enum DEVONthinkSaveOptions : AEKeyword {
    case yes = 0x79657320 /* b'yes ' */
    case no = 0x6e6f2020 /* b'no  ' */
    case ask = 0x61736b20 /* b'ask ' */
}

// MARK: DEVONthinkPrintingErrorHandling
@objc public enum DEVONthinkPrintingErrorHandling : AEKeyword {
    case standard = 0x6c777374 /* b'lwst' */
    case detailed = 0x6c776474 /* b'lwdt' */
}

// MARK: DEVONthinkTextAlignment
@objc public enum DEVONthinkTextAlignment : AEKeyword {
    case left = 0x44416130 /* b'DAa0' */
    case center = 0x44416131 /* b'DAa1' */
    case right = 0x44416132 /* b'DAa2' */
    case justified = 0x44416133 /* b'DAa3' */
    case natural = 0x44416134 /* b'DAa4' */
}

// MARK: DEVONthinkChatEngine
@objc public enum DEVONthinkChatEngine : AEKeyword {
    case appleAI = 0x41504149 /* b'APAI' */
    case chatGPT = 0x43475054 /* b'CGPT' */
    case claude = 0x434c4155 /* b'CLAU' */
    case gemini = 0x47454d49 /* b'GEMI' */
    case mistral = 0x4d494149 /* b'MIAI' */
    case perplexity = 0x50525058 /* b'PRPX' */
    case openRouter = 0x4f505254 /* b'OPRT' */
    case openAICompatible = 0x34416c6c /* b'4All' */
    case lmStudio = 0x4c4d5354 /* b'LMST' */
    case ollama = 0x4f4c4d41 /* b'OLMA' */
    case remoteOllama = 0x4f4c4c41 /* b'OLLA' */
}

// MARK: DEVONthinkChatUsage
@objc public enum DEVONthinkChatUsage : AEKeyword {
    case cheapest = 0x55675530 /* b'UgU0' */
    case auto = 0x55675531 /* b'UgU1' */
    case best = 0x55675532 /* b'UgU2' */
}

// MARK: DEVONthinkComparisonType
@objc public enum DEVONthinkComparisonType : AEKeyword {
    case dataComparison = 0x70747030 /* b'ptp0' */
    case tagsComparison = 0x70747031 /* b'ptp1' */
}

// MARK: DEVONthinkConcordanceSorting
@objc public enum DEVONthinkConcordanceSorting : AEKeyword {
    case weight = 0x77676874 /* b'wght' */
    case frequency = 0x66726571 /* b'freq' */
}

// MARK: DEVONthinkConvertType
@objc public enum DEVONthinkConvertType : AEKeyword {
    case bookmark = 0x44546e78 /* b'DTnx' */
    case simple = 0x63747031 /* b'ctp1' */
    case rich = 0x63747032 /* b'ctp2' */
    case note = 0x6e6f7465 /* b'note' */
    case markdown = 0x6d6b646e /* b'mkdn' */
    case html = 0x68746d6c /* b'html' */
    case webarchive = 0x77626172 /* b'wbar' */
    case pdfDocument = 0x70646620 /* b'pdf ' */
    case singlePagePDFDocument = 0x63747034 /* b'ctp4' */
    case pdfWithoutAnnotations = 0x63747033 /* b'ctp3' */
    case pdfWithAnnotationsBurntIn = 0x63747035 /* b'ctp5' */
}

// MARK: DEVONthinkDataType
@objc public enum DEVONthinkDataType : AEKeyword {
    case group = 0x44546772 /* b'DTgr' */
    case smartGroup = 0x44547367 /* b'DTsg' */
    case feed = 0x66656564 /* b'feed' */
    case bookmark = 0x44546e78 /* b'DTnx' */
    case formattedNote = 0x44546674 /* b'DTft' */
    case html = 0x68746d6c /* b'html' */
    case webarchive = 0x77626172 /* b'wbar' */
    case markdown = 0x6d6b646e /* b'mkdn' */
    case txt = 0x74787420 /* b'txt ' */
    case rtf = 0x72746620 /* b'rtf ' */
    case rtfd = 0x72746664 /* b'rtfd' */
    case picture = 0x70696374 /* b'pict' */
    case multimedia = 0x71757469 /* b'quti' */
    case pdfDocument = 0x70646620 /* b'pdf ' */
    case sheet = 0x7461626c /* b'tabl' */
    case xml = 0x786d6c20 /* b'xml ' */
    case propertyList = 0x706c6973 /* b'plis' */
    case appleScriptFile = 0x61707363 /* b'apsc' */
    case email = 0x656d6c20 /* b'eml ' */
    case unknown = 0x2a2a2a2a /* b'****' */
}

// MARK: DEVONthinkImageEngine
@objc public enum DEVONthinkImageEngine : AEKeyword {
    case dallE2 = 0x44616c32 /* b'Dal2' */
    case dallE3 = 0x44616c33 /* b'Dal3' */
    case gptImage1 = 0x47544931 /* b'GTI1' */
    case fluxSchnell = 0x466c7853 /* b'FlxS' */
    case fluxPro = 0x466c7850 /* b'FlxP' */
    case fluxProUltra = 0x466c7855 /* b'FlxU' */
    case recraft3 = 0x52636633 /* b'Rcf3' */
    case stableDiffusion = 0x5374444c /* b'StDL' */
    case stableDiffusionTurbo = 0x53744454 /* b'StDT' */
    case imagen3Fast = 0x47496746 /* b'GIgF' */
    case imagen3 = 0x47496733 /* b'GIg3' */
    case imagen4 = 0x47496734 /* b'GIg4' */
    case imagen4Fast = 0x47493446 /* b'GI4F' */
    case imagen4Ultra = 0x47493455 /* b'GI4U' */
    case nanoBanana = 0x47494e42 /* b'GINB' */
}

// MARK: DEVONthinkReminderAlarm
@objc public enum DEVONthinkReminderAlarm : AEKeyword {
    case noAlarm = 0x72613030 /* b'ra00' */
    case dock = 0x72613032 /* b'ra02' */
    case sound = 0x72613033 /* b'ra03' */
    case speak = 0x72613034 /* b'ra04' */
    case notification = 0x72613035 /* b'ra05' */
    case alert = 0x72613237 /* b'ra27' */
    case openInternally = 0x72613330 /* b'ra30' */
    case openExternally = 0x72613235 /* b'ra25' */
    case launch = 0x72613234 /* b'ra24' */
    case mailWithItemLink = 0x72613239 /* b'ra29' */
    case mailWithAttachment = 0x72613937 /* b'ra97' */
    case addToReadingList = 0x72613236 /* b'ra26' */
    case embeddedScript = 0x72613939 /* b'ra99' */
    case embeddedJXAScript = 0x72613938 /* b'ra98' */
    case externalScript = 0x72613036 /* b'ra06' */
}

// MARK: DEVONthinkReminderDay
@objc public enum DEVONthinkReminderDay : AEKeyword {
    case noDay = 0x72643030 /* b'rd00' */
    case sunday = 0x72643031 /* b'rd01' */
    case monday = 0x72643032 /* b'rd02' */
    case tuesday = 0x72643033 /* b'rd03' */
    case wednesday = 0x72643034 /* b'rd04' */
    case thursday = 0x72643035 /* b'rd05' */
    case friday = 0x72643036 /* b'rd06' */
    case saturday = 0x72643037 /* b'rd07' */
    case anyDay = 0x72643038 /* b'rd08' */
    case workdays = 0x72643039 /* b'rd09' */
    case weekend = 0x72643130 /* b'rd10' */
}

// MARK: DEVONthinkReminderSchedule
@objc public enum DEVONthinkReminderSchedule : AEKeyword {
    case never = 0x72647330 /* b'rds0' */
    case once = 0x72647331 /* b'rds1' */
    case hourly = 0x72647332 /* b'rds2' */
    case daily = 0x72647333 /* b'rds3' */
    case weekly = 0x72647334 /* b'rds4' */
    case monthly = 0x72647335 /* b'rds5' */
    case yearly = 0x72647336 /* b'rds6' */
}

// MARK: DEVONthinkReminderWeek
@objc public enum DEVONthinkReminderWeek : AEKeyword {
    case noWeek = 0x726d7730 /* b'rmw0' */
    case lastWeek = 0x726d7735 /* b'rmw5' */
    case firstWeek = 0x726d7731 /* b'rmw1' */
    case secondWeek = 0x726d7732 /* b'rmw2' */
    case thirdWeek = 0x726d7733 /* b'rmw3' */
    case fourthWeek = 0x726d7734 /* b'rmw4' */
}

// MARK: DEVONthinkRuleEvent
@objc public enum DEVONthinkRuleEvent : AEKeyword {
    case noEvent = 0x72763030 /* b'rv00' */
    case openEvent = 0x72763035 /* b'rv05' */
    case openExternallyEvent = 0x72763036 /* b'rv06' */
    case editExternallyEvent = 0x72763138 /* b'rv18' */
    case launchEvent = 0x72763037 /* b'rv07' */
    case creationEvent = 0x72763031 /* b'rv01' */
    case importEvent = 0x72763032 /* b'rv02' */
    case clippingEvent = 0x72763033 /* b'rv03' */
    case downloadEvent = 0x72763034 /* b'rv04' */
    case renameEvent = 0x72763043 /* b'rv0C' */
    case moveEvent = 0x72763041 /* b'rv0A' */
    case classifyEvent = 0x72763042 /* b'rv0B' */
    case replicateEvent = 0x72763044 /* b'rv0D' */
    case duplicateEvent = 0x72763046 /* b'rv0F' */
    case taggingEvent = 0x72763045 /* b'rv0E' */
    case flaggingEvent = 0x72763133 /* b'rv13' */
    case labellingEvent = 0x72763132 /* b'rv12' */
    case ratingEvent = 0x72763135 /* b'rv15' */
    case moveIntoDatabaseEvent = 0x72763038 /* b'rv08' */
    case moveToExternalFolderEvent = 0x72763039 /* b'rv09' */
    case commentingEvent = 0x72763137 /* b'rv17' */
    case convertEvent = 0x72763134 /* b'rv14' */
    case ocrEvent = 0x72763130 /* b'rv10' */
    case imprintEvent = 0x72763131 /* b'rv11' */
    case trashingEvent = 0x72763136 /* b'rv16' */
}

// MARK: DEVONthinkSearchComparison
@objc public enum DEVONthinkSearchComparison : AEKeyword {
    case noCase = 0x6e6f6361 /* b'noca' */
    case noUmlauts = 0x6e6f756d /* b'noum' */
    case fuzzy = 0x66757a7a /* b'fuzz' */
    case related = 0x73696d69 /* b'simi' */
}

// MARK: DEVONthinkSummaryStyle
@objc public enum DEVONthinkSummaryStyle : AEKeyword {
    case listSummary = 0x53664c69 /* b'SfLi' */
    case keyPointsSummary = 0x53664b79 /* b'SfKy' */
    case tableSummary = 0x53665462 /* b'SfTb' */
    case textSummary = 0x53665478 /* b'SfTx' */
    case customSummary = 0x53664373 /* b'SfCs' */
}

// MARK: DEVONthinkSummaryType
@objc public enum DEVONthinkSummaryType : AEKeyword {
    case markdown = 0x6d6b646e /* b'mkdn' */
    case simple = 0x63747031 /* b'ctp1' */
    case rich = 0x63747032 /* b'ctp2' */
    case sheet = 0x7461626c /* b'tabl' */
}

// MARK: DEVONthinkTagType
@objc public enum DEVONthinkTagType : AEKeyword {
    case noTag = 0x6e746167 /* b'ntag' */
    case ordinaryTag = 0x6f746167 /* b'otag' */
    case groupTag = 0x67746167 /* b'gtag' */
}

// MARK: DEVONthinkUpdateMode
@objc public enum DEVONthinkUpdateMode : AEKeyword {
    case replacing = 0x556d5270 /* b'UmRp' */
    case appending = 0x556d4170 /* b'UmAp' */
    case inserting = 0x556d496e /* b'UmIn' */
}

// MARK: DEVONthinkOCRConvertType
@objc public enum DEVONthinkOCRConvertType : AEKeyword {
    case annotateDocument = 0x616e6e6f /* b'anno' */
    case commentDocument = 0x636f6d74 /* b'comt' */
    case pdfDocument = 0x70646620 /* b'pdf ' */
    case rtf = 0x72746620 /* b'rtf ' */
    case wordDocument = 0x646f6378 /* b'docx' */
    case webarchive = 0x77626172 /* b'wbar' */
}

// MARK: DEVONthinkBorderStyleType
@objc public enum DEVONthinkBorderStyleType : AEKeyword {
    case none = 0x69627331 /* b'ibs1' */
    case rectangle = 0x69627332 /* b'ibs2' */
    case roundedRectangle = 0x69627333 /* b'ibs3' */
    case oval = 0x69627334 /* b'ibs4' */
    case leftArrow = 0x69627335 /* b'ibs5' */
    case rightArrow = 0x69627336 /* b'ibs6' */
}

// MARK: DEVONthinkImprintPosition
@objc public enum DEVONthinkImprintPosition : AEKeyword {
    case topLeft = 0x69703031 /* b'ip01' */
    case topCenter = 0x69703032 /* b'ip02' */
    case topRight = 0x69703033 /* b'ip03' */
    case centerLeft = 0x69703034 /* b'ip04' */
    case centered = 0x69703035 /* b'ip05' */
    case centerRight = 0x69703036 /* b'ip06' */
    case bottomLeft = 0x69703037 /* b'ip07' */
    case bottomCenter = 0x69703038 /* b'ip08' */
    case bottomRight = 0x69703039 /* b'ip09' */
}

// MARK: DEVONthinkOccurrenceType
@objc public enum DEVONthinkOccurrenceType : AEKeyword {
    case everyPage = 0x696f7431 /* b'iot1' */
    case firstPageOnly = 0x696f7432 /* b'iot2' */
    case evenPages = 0x696f7433 /* b'iot3' */
    case oddPages = 0x696f7434 /* b'iot4' */
}

// MARK: DEVONthinkGenericMethods
@objc public protocol DEVONthinkGenericMethods {
    @objc optional func closeSaving(_ saving: DEVONthinkSaveOptions) // Close a window, tab or database.
    @objc optional func save() // Save a window or tab.
    @objc optional func printWithProperties(_ withProperties: [AnyHashable : Any]!, printDialog: Bool) // Print a window or tab.
    @objc optional func bold() // Bold some text
    @objc optional func italicize() // Italicize some text
    @objc optional func plain() // Make some text plain
    @objc optional func reformat() // Reformat some text. Similar to WordService's Reformat service.
    @objc optional func scrollToVisible() // Scroll to and animate some text.
    @objc optional func strike() // Strike some text
    @objc optional func unbold() // Unbold some text
    @objc optional func underline() // Underline some text
    @objc optional func unitalicize() // Unitalicize some text
    @objc optional func unstrike() // Unstrike some text
    @objc optional func ununderline() // Ununderline some text
    @objc optional func addRowCells(_ cells: [String]!) -> Bool // Add new row to a sheet.
    @objc optional func deleteRowAtPosition(_ position: Int) -> Bool // Remove row at specified position from a sheet.
    @objc optional func displayChatDialogName(_ name: Any!, role: Any!, prompt: Any!) -> Any // Display a dialog to show the response for a chat prompt for the current document. Either the selected text or the complete document is used.
    @objc optional func getCellAtColumn(_ column: Any!, row: Int) -> Any // Get content of cell at specified position of a sheet.
    @objc optional func setCellAtColumn(_ column: Any!, row: Int, to: String!) -> Bool // Set cell at specified position of a sheet.
}

// MARK: DEVONthinkApplication
@objc public protocol DEVONthinkApplication: SBApplicationProtocol {
    @objc optional func windows() -> SBElementArray
    @objc optional var name: String { get } // The name of the application.
    @objc optional var frontmost: Bool { get } // Is this the active application?
    @objc optional var version: String { get } // The version number of the application.
    @objc optional func quitSaving(_ saving: DEVONthinkSaveOptions) // Quit the application.
    @objc optional func exists(_ x: Any!) -> Bool // Verify that an object exists.
    @objc optional func addCustomMetaData(_ x: Any!, for for_: String!, to: DEVONthinkRecord!, as: Any!) -> Bool // Add user-defined metadata to a record or updates already existing metadata of a record. Setting a value for an unknown key automatically adds a definition to Settings > Data.
    @objc optional func addDownload(_ x: String!, automatic: Bool, password: Any!, referrer: Any!, user: Any!) -> Bool // Add a URL to the download manager.
    @objc optional func addReadingListRecord(_ record: Any!, URL: Any!, title: Any!) -> Bool // Add record or URL to reading list.
    @objc optional func addReminder(_ x: [AnyHashable : Any]!, to: DEVONthinkRecord!) -> Any // Add a new reminder to a record.
    @objc optional func checkFileIntegrityOfDatabase(_ database: DEVONthinkDatabase!) -> Int // Check file integrity of database.
    @objc optional func classifyRecord(_ record: DEVONthinkRecord!, in in_: Any!, comparison: DEVONthinkComparisonType, tags: Bool) -> Any // Get a list of classification proposals.
    @objc optional func compareRecord(_ record: Any!, content: Any!, to: Any!, comparison: DEVONthinkComparisonType) -> Any // Get a list of similar records, either by specifying a record or a content.
    @objc optional func compressDatabase(_ database: DEVONthinkDatabase!, password: Any!, to: String!) -> Bool // Compress a database into a Zip archive.
    @objc optional func convertRecord(_ record: Any!, to: DEVONthinkConvertType, in in_: Any!) -> Any // Convert a record to plain or rich text, formatted note or HTML and create a new record afterwards.
    @objc optional func convertFeedToHTML(_ x: String!, baseURL: Any!) -> Any // Convert a RSS, RDF, JSON or Atom feed to HTML.
    @objc optional func createDatabase(_ x: String!, encryptionKey: Any!, size: Int) -> Any // Create a new database.
    @objc optional func createFormattedNoteFrom(_ x: String!, agent: Any!, in in_: Any!, name: Any!, readability: Bool, referrer: Any!, source: Any!) -> Any // Create a new formatted note from a web page.
    @objc optional func createLocation(_ x: String!, in in_: Any!) -> Any // Create a hierarchy of groups if necessary.
    @objc optional func createMarkdownFrom(_ x: String!, agent: Any!, in in_: Any!, name: Any!, readability: Bool, referrer: Any!) -> Any // Create a Markdown document from a web resource.
    @objc optional func createPDFDocumentFrom(_ x: String!, agent: Any!, in in_: Any!, name: Any!, pagination: Bool, readability: Bool, referrer: Any!, width: NSNumber!) -> Any // Create a new PDF document with or without pagination from a web resource.
    @objc optional func createRecordWith(_ x: [AnyHashable : Any]!, in in_: Any!) -> Any // Create a new record.
    @objc optional func createThumbnailFor(_ for_: DEVONthinkRecord!) -> Bool // Create or update existing thumbnail of a record. Thumbnailing is performed asynchronously in the background.
    @objc optional func createWebDocumentFrom(_ x: String!, agent: Any!, in in_: Any!, name: Any!, readability: Bool, referrer: Any!) -> Any // Create a new record (picture, PDF or web archive) from a web resource.
    @objc optional func deleteRecord(_ record: Any!, in in_: Any!) -> Bool // Delete all instances of a record from the database or one instance from the specified group.
    @objc optional func deleteThumbnailOf(_ of: DEVONthinkRecord!) -> Bool // Delete existing thumbnail of a record.
    @objc optional func deleteWorkspace(_ x: String!) -> Bool // Delete a workspace.
    @objc optional func doJavaScript(_ x: String!, in in_: Any!) -> Any // Executes a string of JavaScript code (optionally in the web view of a think window).
    @objc optional func downloadImageForPrompt(_ x: String!, promptStrength: Double, image: Any!, engine: DEVONthinkImageEngine, quality: String!, size: String!, style: String!, seed: Int) -> Any // Download image for a prompt.
    @objc optional func downloadJSONFrom(_ x: String!, agent: Any!, method: Any!, password: Any!, post: Any!, referrer: Any!, user: Any!) -> Any // Download a JSON object.
    @objc optional func downloadMarkupFrom(_ x: String!, agent: Any!, encoding: Any!, method: Any!, password: Any!, post: Any!, referrer: Any!, user: Any!) -> Any // Download an HTML or XML page (including RSS, RDF or Atom feeds).
    @objc optional func downloadURL(_ x: String!, agent: Any!, method: Any!, password: Any!, post: Any!, referrer: Any!, user: Any!) -> Any // Download a URL.
    @objc optional func displayAuthenticationDialog() -> Any // Display a dialog to enter a username and its password.
    @objc optional func displayDateEditorDefaultDate(_ defaultDate: Any!, info: Any!) -> Any // Display a dialog to enter a date.
    @objc optional func displayGroupSelectorButtons(_ buttons: Any!, for for_: Any!, name: Bool, tags: Bool) -> Any // Display a dialog to select a (destination) group.
    @objc optional func displayNameEditorDefaultAnswer(_ defaultAnswer: Any!, info: Any!) -> Any // Display a dialog to enter a name.
    @objc optional func duplicateRecord(_ record: Any!, to: DEVONthinkParent!) -> Any // Duplicate a record.
    @objc optional func existsRecordAt(_ x: String!, in in_: Any!) -> Bool // Check if at least one record exists at the specified location.
    @objc optional func existsRecordWithComment(_ x: String!, in in_: Any!) -> Bool // Check if at least one record with the specified comment exists.
    @objc optional func existsRecordWithContentHash(_ x: String!, in in_: Any!) -> Bool // Check if at least one record with the specified content hash exists.
    @objc optional func existsRecordWithFile(_ x: String!, in in_: Any!) -> Bool // Check if at least one record with the specified last path component exists.
    @objc optional func existsRecordWithPath(_ x: String!, in in_: Any!) -> Bool // Check if at least one record with the specified path exists.
    @objc optional func existsRecordWithURL(_ x: String!, in in_: Any!) -> Bool // Check if at least one record with the specified URL exists.
    @objc optional func exportRecord(_ record: DEVONthinkRecord!, to: String!, DEVONtech_Storage: Bool) -> Any // Export a record (and its children).
    @objc optional func exportTagsOfRecord(_ record: DEVONthinkRecord!) -> Bool // Export Finder tags of a record.
    @objc optional func exportWebsiteRecord(_ record: DEVONthinkRecord!, to: String!, template template_: Any!, indexPages: Bool, encoding: Any!, entities: Bool) -> Any // Export a record (and its children) as a website.
    @objc optional func extractKeywordsFromRecord(_ record: DEVONthinkRecord!, barcodes: Bool, existingTags: Bool, hashTags: Bool, imageTags: Bool) -> Any // Extract list of keywords from a record. The list is sorted by number of occurrences.
    @objc optional func getCachedDataForURL(_ x: String!, from: Any!) -> Any // Get cached data for URL of a resource which is part of a loaded webpage and its DOM tree, rendered in a think tab/window.
    @objc optional func getChatCapabilitiesForEngine(_ x: DEVONthinkChatEngine, model: String!) -> Any // Retrieve capabilities of a model for a certain engine.
    @objc optional func getChatModelsForEngine(_ x: DEVONthinkChatEngine) -> [Any] // Retrieve list of supported models of a chat engine.
    @objc optional func getChatResponseForMessage(_ x: Any!, record: Any!, mode: Any!, image: Any!, URL: Any!, model: Any!, role: Any!, engine: DEVONthinkChatEngine, temperature: Double, thinking: Bool, toolCalls: Bool, usage: DEVONthinkChatUsage, as: Any!) -> Any // Retrieve the response for a chat message. The chat might perform a web, Wikipedia or PubMed search if necessary depending on the parameters and the settings.
    @objc optional func getConcordanceOfRecord(_ record: DEVONthinkContent!, sortedBy: DEVONthinkConcordanceSorting) -> Any // Get list of words of a record. Supports both documents and groups/feeds.
    @objc optional func getCustomMetaDataDefaultValue(_ defaultValue: Any!, for for_: String!, from: DEVONthinkRecord!) -> Any // Get user-defined metadata from a record.
    @objc optional func getDatabaseWithId(_ x: Int) -> Any // Get database with the specified id.
    @objc optional func getDatabaseWithUuid(_ x: String!) -> Any // Get database with the specified uuid.
    @objc optional func getEmbeddedImagesOf(_ x: String!, baseURL: Any!, fileType: Any!) -> Any // Get the URLs of all embedded images of an HTML page.
    @objc optional func getEmbeddedObjectsOf(_ x: String!, baseURL: Any!, fileType: Any!) -> Any // Get the URLs of all embedded objects of an HTML page.
    @objc optional func getEmbeddedSheetsAndScriptsOf(_ x: String!, baseURL: Any!, fileType: Any!) -> Any // Get the URLs of all embedded style sheets and scripts of an HTML page.
    @objc optional func getFaviconOf(_ x: String!, baseURL: Any!) -> Any // Get the favicon of an HTML page.
    @objc optional func getFeedItemsOf(_ x: String!, baseURL: Any!) -> Any // Get the feed items of a RSS, RDF, JSON or Atom feed.
    @objc optional func getFramesOf(_ x: String!, baseURL: Any!) -> Any // Get the URLs of all frames of an HTML page.
    @objc optional func getItemsOfFeed(_ x: String!, baseURL: Any!) -> Any // Get the items of a RSS, RDF, JSON or Atom feed as dictionaries. 'get feed items of' is recommended for new scripts.
    @objc optional func getLinksOf(_ x: String!, baseURL: Any!, containing: Any!, fileType: Any!) -> Any // Get the URLs of all links of an HTML page.
    @objc optional func getMetadataOf(_ x: String!, baseURL: Any!, markdown: Any!) -> Any // Get the metadata of an HTML page or of a Markdown document.
    @objc optional func getRecordAt(_ x: String!, in in_: Any!) -> Any // Search for record at the specified location.
    @objc optional func getRecordWithId(_ x: Int, in in_: Any!) -> Any // Get record with the specified id.
    @objc optional func getRecordWithUuid(_ x: String!, in in_: Any!) -> Any // Get record with the specified uuid or item link.
    @objc optional func getRichTextOf(_ x: String!, baseURL: Any!) -> Any // Get the rich text of an HTML page.
    @objc optional func getTextOf(_ x: String!) -> Any // Get the text of an HTML page.
    @objc optional func getTitleOf(_ x: String!) -> Any // Get the title of an HTML page.
    @objc optional func getVersionsOfRecord(_ record: DEVONthinkRecord!) -> Any // Get saved versions of a record.
    @objc optional func hideProgressIndicator() -> Bool // Hide a visible progress indicator.
    @objc optional func importAttachmentsOfRecord(_ record: DEVONthinkRecord!, to: Any!) -> Any // Import attachments of an email.
    @objc optional func importPath(_ x: String!, from: Any!, name: Any!, placeholders: Any!, to: Any!) -> Any // Import a file or folder (including its subfolders).
    @objc optional func importTemplate(_ x: String!, to: Any!) -> Any // Import a template. Template scripts are not supported and revision-proof databases do not support any templates at all.
    @objc optional func indexPath(_ x: String!, to: Any!) -> Any // Index a file or folder (including its subfolders). Not supported by revision-proof databases.
    @objc optional func loadWorkspace(_ x: String!) -> Bool // Load a workspace.
    @objc optional func logMessageRecord(_ record: Any!, info: Any!) -> Bool // Log info for a record, file or action to the Window > Log panel
    @objc optional func lookupRecordsWithComment(_ x: String!, in in_: Any!) -> Any // Lookup records with specified comment.
    @objc optional func lookupRecordsWithContentHash(_ x: String!, in in_: Any!) -> Any // Lookup records with specified content hash.
    @objc optional func lookupRecordsWithFile(_ x: String!, in in_: Any!) -> Any // Lookup records whose last path component is the specified file.
    @objc optional func lookupRecordsWithPath(_ x: String!, in in_: Any!) -> Any // Lookup records with specified path.
    @objc optional func lookupRecordsWithTags(_ x: [String]!, any: Bool, in in_: Any!) -> Any // Lookup records with all or any of the specified tags.
    @objc optional func lookupRecordsWithURL(_ x: String!, in in_: Any!) -> Any // Lookup records with specified URL.
    @objc optional func mergeIn(_ in_: Any!, records: [DEVONthinkRecord]!) -> Any // Merge either a list of records as an RTF(D)/a PDF document or merge a list of not indexed groups/tags.
    @objc optional func moveRecord(_ record: Any!, from: Any!, to: DEVONthinkParent!) -> Any // Move all instances of a record to a different group.  Specify the 'from' group to move a single instance to a different group.
    @objc optional func moveIntoDatabaseRecord(_ record: DEVONthinkRecord!) -> Bool // Move an external/indexed record (and its children) into the database. Not supported by revision-proof databases.
    @objc optional func moveToExternalFolderRecord(_ record: DEVONthinkRecord!, to: Any!) -> Bool // Move an internal/imported record (and its children) to the enclosing external folder in the filesystem. Creation/Modification dates, Spotlight comments and OpenMeta tags are immediately updated. Not supported by revision-proof databases.
    @objc optional func openDatabase(_ x: String!) -> Any // Open an existing database.
    @objc optional func openTabForRecord(_ record: Any!, URL: Any!, referrer: Any!, in in_: Any!) -> Any // Open a new tab for the specified URL or record in a think window.
    @objc optional func openWindowForRecord(_ record: DEVONthinkRecord!, enforcement: Bool) -> Any // Open a (new) main or document window for the specified record. Only recommended for main windows, use 'open tab for' for document windows.
    @objc optional func optimizeDatabase(_ database: DEVONthinkDatabase!) -> Bool // Backup & optimize a database.
    @objc optional func pasteClipboardTo(_ to: Any!) -> Any // Create a new record with the contents of the clipboard.
    @objc optional func performSmartRuleName(_ name: Any!, record: Any!, trigger: DEVONthinkRuleEvent) -> Bool // Perform one or all smart rules.
    @objc optional func refreshRecord(_ record: DEVONthinkRecord!) -> Bool // Refresh a record. Currently only supported by feeds but not by revision-proof databases.
    @objc optional func replicateRecord(_ record: Any!, to: DEVONthinkParent!) -> Any // Replicate a record.
    @objc optional func restoreRecordWithVersion(_ version: DEVONthinkRecord!) -> Bool // Restore saved version of a record.
    @objc optional func saveVersionOfRecord(_ record: DEVONthinkRecord!) -> Any // Save version of current record. NOTE: Use this command right before editing the contents, not afterwards, as duplicates are automatically removed.
    @objc optional func saveWorkspace(_ x: String!) -> Bool // Save a workspace.
    @objc optional func searchComparison(_ comparison: DEVONthinkSearchComparison, excludeSubgroups: Bool, in in_: Any!) -> Any // Search for records in specified group or all databases.
    @objc optional func showProgressIndicator(_ x: String!, cancelButton: Bool, steps: NSNumber!) -> Bool // Show a progress indicator or update an already visible indicator. You have to ensure that the indicator is hidden again via 'hide progress indicator' when the script ends or if an error occurs.
    @objc optional func showSearch() -> Bool // Perform search in frontmost main window. Opens a new main window if there's none.
    @objc optional func startDownloads() -> Bool // Start queue of download manager.
    @objc optional func stepProgressIndicator() -> Bool // Go to next step of a progress.
    @objc optional func stopDownloads() -> Bool // Stop queue of download manager.
    @objc optional func summarizeAnnotationsOfIn(_ in_: Any!, records: [DEVONthinkContent]!, to: DEVONthinkSummaryType) -> Any // Summarize highlights & annotations of records. PDF, RTF(D), Markdown and web documents are currently supported.
    @objc optional func summarizeContentsOfIn(_ in_: Any!, records: [DEVONthinkContent]!, to: DEVONthinkSummaryType, as: DEVONthinkSummaryStyle) -> Any // Summarize content of records.
    @objc optional func summarizeMentionsOfIn(_ in_: Any!, records: [DEVONthinkContent]!, to: DEVONthinkSummaryType) -> Any // Summarize mentions of records.
    @objc optional func summarizeText(_ x: String!, as: DEVONthinkSummaryStyle) -> Any // Summarizes text.
    @objc optional func synchronizeRecord(_ record: Any!, database: Any!) -> Bool // Synchronizes records with the filesystem or databases with their sync locations. Only one of both operations is supported.
    @objc optional func transcribeRecord(_ record: DEVONthinkContent!, language: String!, timestamps: Bool) -> Any // Transcribes speech, text or notes of a record.
    @objc optional func updateRecord(_ record: DEVONthinkRecord!, withText: Any!, mode: DEVONthinkUpdateMode, URL: Any!) -> Bool // Update text of a plain/rich text, Markdown document, formatted note or HTML page. Not supported by revision-proof databases.
    @objc optional func updateThumbnailOf(_ of: DEVONthinkRecord!) -> Bool // Update existing thumbnail of a record. Thumbnailing is performed asynchronously in the background.
    @objc optional func verifyDatabase(_ database: DEVONthinkDatabase!) -> Int // Verify a database.
    @objc optional func convertImageRecord(_ record: DEVONthinkContent!, to: Any!, fileType: DEVONthinkOCRConvertType, waitingForReply: Bool) -> Any // Converts a record to a new record and applies OCR.
    @objc optional func ocrFile(_ file: String!, attributes: Any!, to: Any!, fileType: DEVONthinkOCRConvertType, waitingForReply: Bool) -> Any // Imports a PDF document or image with OCR.
    @objc optional func imprinterConfigurationNames() -> Any // Returns list of imprinter configuration names
    @objc optional func imprintConfiguration(_ x: String!, to: DEVONthinkContent!, waitingForReply: Bool) -> Bool // Imprint the record with a given imprinter configuration. Not supported by revision-proof databases.
    @objc optional func imprintRecord(_ record: DEVONthinkContent!, backgroundColor: Any!, borderColor: Any!, borderStyle: DEVONthinkBorderStyleType, borderWidth: Int, font: String!, foregroundColor: Any!, occurence: DEVONthinkOccurrenceType, outlined: Bool, position: DEVONthinkImprintPosition, rotation: Int, size: Int, strikeThrough: Bool, text: String!, underlined: Bool, xOffset: Int, yOffset: Int, waitingForReply: Bool) -> Bool // Imprint the record with a configuration defined in the parameters. Not supported by revision-proof databases.
    @objc optional func databases() -> SBElementArray
    @objc optional func thinkWindows() -> SBElementArray
    @objc optional func mainWindows() -> SBElementArray
    @objc optional func documentWindows() -> SBElementArray
    @objc optional func selectedRecords() -> SBElementArray
    @objc optional var batesNumber: Int { get } // Current bates number.
    @objc optional var cancelledProgress: Bool { get } // Specifies if a process with a visible progress indicator should be cancelled.
    @objc optional var currentChatEngine: Any { get } // The default chat engine.
    @objc optional var currentChatModel: Any { get } // The default chat model.
    @objc optional var currentGroup: Any { get } // The (selected) group of the frontmost window of the current database. Returns root of current database if no current group exists.
    @objc optional var currentWorkspace: Any { get } // The name of the currently used workspace.
    @objc optional var currentDatabase: Any { get } // The currently used database.
    @objc optional var contentRecord: Any { get } // The record of the visible document in the frontmost think window.
    @objc optional var inbox: Any { get } // The global inbox.
    @objc optional var incomingGroup: Any { get } // The default group for new notes. Either global inbox or incoming group of current database if global inbox isn't available.
    @objc optional var labelNames: Any { get } // List of all 7 label names.
    @objc optional var lastDownloadedResponse: Any { get } // The last downloaded HTTP(S) response.
    @objc optional var lastDownloadedURL: Any { get } // The actual URL of the last download.
    @objc optional var preferredImportDestination: Any { get } // The default destination for data from external sources. See Settings > Import > Destination.
    @objc optional var readingList: Any { get } // The items of the reading list.
    @objc optional var selection: Any { get } // The current selection of the frontmost main window or the record of the frontmost document window. 'selected records' element is recommended instead especially for bulk retrieval of properties like UUID.
    @objc optional var strictDuplicateRecognition: Bool { get } // Specifies if recognition of duplicates is strict (exact) or not (fuzzy).
    @objc optional var workspaces: Any { get } // The names of all available workspaces.
    @objc optional func setBatesNumber(_ batesNumber: Int) // Current bates number.
    @objc optional func setStrictDuplicateRecognition(_ strictDuplicateRecognition: Bool) // Specifies if recognition of duplicates is strict (exact) or not (fuzzy).
}
extension SBApplication: DEVONthinkApplication {}

// MARK: DEVONthinkWindow
@objc public protocol DEVONthinkWindow: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional var name: String { get } // The title of the window.
    @objc optional func id() -> Int // The unique identifier of the window.
    @objc optional var index: Int { get } // The index of the window, ordered front to back.
    @objc optional var bounds: NSRect { get } // The bounding rectangle of the window.
    @objc optional var closeable: Bool { get } // Does the window have a close button?
    @objc optional var miniaturizable: Bool { get } // Does the window have a minimize button?
    @objc optional var miniaturized: Bool { get } // Is the window minimized right now?
    @objc optional var resizable: Bool { get } // Can the window be resized?
    @objc optional var visible: Bool { get } // Is the window visible right now?
    @objc optional var zoomable: Bool { get } // Does the window have a zoom button?
    @objc optional var zoomed: Bool { get } // Is the window zoomed right now?
    @objc optional func setIndex(_ index: Int) // The index of the window, ordered front to back.
    @objc optional func setBounds(_ bounds: NSRect) // The bounding rectangle of the window.
    @objc optional func setMiniaturized(_ miniaturized: Bool) // Is the window minimized right now?
    @objc optional func setVisible(_ visible: Bool) // Is the window visible right now?
    @objc optional func setZoomed(_ zoomed: Bool) // Is the window zoomed right now?
}
extension SBObject: DEVONthinkWindow {}

// MARK: DEVONthinkRichText
@objc public protocol DEVONthinkRichText: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func attachments() -> SBElementArray
    @objc optional func attributeRuns() -> SBElementArray
    @objc optional func characters() -> SBElementArray
    @objc optional func paragraphs() -> SBElementArray
    @objc optional func words() -> SBElementArray
    @objc optional var font: Any { get } // The name of the font of the first character.
    @objc optional var size: NSNumber { get } // The size in points of the first character.
    @objc optional var color: Any { get } // The color of the first character.
    @objc optional func addCustomMetaDataFor(_ for_: String!, to: DEVONthinkRecord!, as: Any!) -> Bool // Add user-defined metadata to a record or updates already existing metadata of a record. Setting a value for an unknown key automatically adds a definition to Settings > Data.
    @objc optional func setFont(_ font: Any!) // The name of the font of the first character.
    @objc optional func setSize(_ size: NSNumber!) // The size in points of the first character.
    @objc optional func setColor(_ color: Any!) // The color of the first character.
    @objc optional var baselineOffset: Double { get } // Number of points shifted above or below the normal baseline.
    @objc optional var background: Any { get } // The background color of the first character.
    @objc optional var firstLineHeadIndent: Double { get } // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional var headIndent: Double { get } // Paragraph head indent of the text (always 0 or positive).
    @objc optional var underlined: Bool { get } // Is the first character underlined?
    @objc optional var lineSpacing: Double { get } // Line spacing of the text.
    @objc optional var multipleLineHeight: Double { get } // Multiple line height of the text.
    @objc optional var maximumLineHeight: Double { get } // Maximum line height of the text.
    @objc optional var minimumLineHeight: Double { get } // Minimum line height of the text.
    @objc optional var paragraphSpacing: Double { get } // Paragraph spacing of the text.
    @objc optional var superscript: Int { get } // The superscript level of the text.
    @objc optional var tailIndent: Double { get } // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional var textContent: Any { get } // The actual text content.
    @objc optional var alignment: DEVONthinkTextAlignment { get } // Alignment of the text.
    @objc optional var URL: Any { get } // Link of the text.
    @objc optional func setBaselineOffset(_ baselineOffset: Double) // Number of points shifted above or below the normal baseline.
    @objc optional func setBackground(_ background: Any!) // The background color of the first character.
    @objc optional func setFirstLineHeadIndent(_ firstLineHeadIndent: Double) // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional func setHeadIndent(_ headIndent: Double) // Paragraph head indent of the text (always 0 or positive).
    @objc optional func setUnderlined(_ underlined: Bool) // Is the first character underlined?
    @objc optional func setLineSpacing(_ lineSpacing: Double) // Line spacing of the text.
    @objc optional func setMultipleLineHeight(_ multipleLineHeight: Double) // Multiple line height of the text.
    @objc optional func setMaximumLineHeight(_ maximumLineHeight: Double) // Maximum line height of the text.
    @objc optional func setMinimumLineHeight(_ minimumLineHeight: Double) // Minimum line height of the text.
    @objc optional func setParagraphSpacing(_ paragraphSpacing: Double) // Paragraph spacing of the text.
    @objc optional func setSuperscript(_ superscript: Int) // The superscript level of the text.
    @objc optional func setTailIndent(_ tailIndent: Double) // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional func setTextContent(_ textContent: Any!) // The actual text content.
    @objc optional func setAlignment(_ alignment: DEVONthinkTextAlignment) // Alignment of the text.
    @objc optional func setURL(_ URL: Any!) // Link of the text.
}
extension SBObject: DEVONthinkRichText {}

// MARK: DEVONthinkAttachment
@objc public protocol DEVONthinkAttachment: DEVONthinkRichText {
    @objc optional var fileName: Any { get } // The path to the file for the attachment
    @objc optional func setFileName(_ fileName: Any!) // The path to the file for the attachment
}
extension SBObject: DEVONthinkAttachment {}

// MARK: DEVONthinkAttributeRun
@objc public protocol DEVONthinkAttributeRun: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func attachments() -> SBElementArray
    @objc optional func attributeRuns() -> SBElementArray
    @objc optional func characters() -> SBElementArray
    @objc optional func paragraphs() -> SBElementArray
    @objc optional func words() -> SBElementArray
    @objc optional var font: Any { get } // The name of the font of the first character.
    @objc optional var size: NSNumber { get } // The size in points of the first character.
    @objc optional var color: Any { get } // The color of the first character.
    @objc optional func setFont(_ font: Any!) // The name of the font of the first character.
    @objc optional func setSize(_ size: NSNumber!) // The size in points of the first character.
    @objc optional func setColor(_ color: Any!) // The color of the first character.
    @objc optional var baselineOffset: Double { get } // Number of points shifted above or below the normal baseline.
    @objc optional var background: Any { get } // The background color of the first character.
    @objc optional var firstLineHeadIndent: Double { get } // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional var headIndent: Double { get } // Paragraph head indent of the text (always 0 or positive).
    @objc optional var underlined: Bool { get } // Is the first character underlined?
    @objc optional var lineSpacing: Double { get } // Line spacing of the text.
    @objc optional var multipleLineHeight: Double { get } // Multiple line height of the text.
    @objc optional var maximumLineHeight: Double { get } // Maximum line height of the text.
    @objc optional var minimumLineHeight: Double { get } // Minimum line height of the text.
    @objc optional var paragraphSpacing: Double { get } // Paragraph spacing of the text.
    @objc optional var superscript: Int { get } // The superscript level of the text.
    @objc optional var tailIndent: Double { get } // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional var textContent: Any { get } // The actual text content.
    @objc optional var alignment: DEVONthinkTextAlignment { get } // Alignment of the text.
    @objc optional var URL: Any { get } // Link of the text.
    @objc optional func setBaselineOffset(_ baselineOffset: Double) // Number of points shifted above or below the normal baseline.
    @objc optional func setBackground(_ background: Any!) // The background color of the first character.
    @objc optional func setFirstLineHeadIndent(_ firstLineHeadIndent: Double) // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional func setHeadIndent(_ headIndent: Double) // Paragraph head indent of the text (always 0 or positive).
    @objc optional func setUnderlined(_ underlined: Bool) // Is the first character underlined?
    @objc optional func setLineSpacing(_ lineSpacing: Double) // Line spacing of the text.
    @objc optional func setMultipleLineHeight(_ multipleLineHeight: Double) // Multiple line height of the text.
    @objc optional func setMaximumLineHeight(_ maximumLineHeight: Double) // Maximum line height of the text.
    @objc optional func setMinimumLineHeight(_ minimumLineHeight: Double) // Minimum line height of the text.
    @objc optional func setParagraphSpacing(_ paragraphSpacing: Double) // Paragraph spacing of the text.
    @objc optional func setSuperscript(_ superscript: Int) // The superscript level of the text.
    @objc optional func setTailIndent(_ tailIndent: Double) // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional func setTextContent(_ textContent: Any!) // The actual text content.
    @objc optional func setAlignment(_ alignment: DEVONthinkTextAlignment) // Alignment of the text.
    @objc optional func setURL(_ URL: Any!) // Link of the text.
}
extension SBObject: DEVONthinkAttributeRun {}

// MARK: DEVONthinkCharacter
@objc public protocol DEVONthinkCharacter: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func attachments() -> SBElementArray
    @objc optional func attributeRuns() -> SBElementArray
    @objc optional func characters() -> SBElementArray
    @objc optional func paragraphs() -> SBElementArray
    @objc optional func words() -> SBElementArray
    @objc optional var font: Any { get } // The name of the font of the first character.
    @objc optional var size: NSNumber { get } // The size in points of the first character.
    @objc optional var color: Any { get } // The color of the first character.
    @objc optional func setFont(_ font: Any!) // The name of the font of the first character.
    @objc optional func setSize(_ size: NSNumber!) // The size in points of the first character.
    @objc optional func setColor(_ color: Any!) // The color of the first character.
    @objc optional var baselineOffset: Double { get } // Number of points shifted above or below the normal baseline.
    @objc optional var background: Any { get } // The background color of the first character.
    @objc optional var firstLineHeadIndent: Double { get } // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional var headIndent: Double { get } // Paragraph head indent of the text (always 0 or positive).
    @objc optional var underlined: Bool { get } // Is the first character underlined?
    @objc optional var lineSpacing: Double { get } // Line spacing of the text.
    @objc optional var multipleLineHeight: Double { get } // Multiple line height of the text.
    @objc optional var maximumLineHeight: Double { get } // Maximum line height of the text.
    @objc optional var minimumLineHeight: Double { get } // Minimum line height of the text.
    @objc optional var paragraphSpacing: Double { get } // Paragraph spacing of the text.
    @objc optional var superscript: Int { get } // The superscript level of the text.
    @objc optional var tailIndent: Double { get } // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional var textContent: Any { get } // The actual text content.
    @objc optional var alignment: DEVONthinkTextAlignment { get } // Alignment of the text.
    @objc optional var URL: Any { get } // Link of the text.
    @objc optional func setBaselineOffset(_ baselineOffset: Double) // Number of points shifted above or below the normal baseline.
    @objc optional func setBackground(_ background: Any!) // The background color of the first character.
    @objc optional func setFirstLineHeadIndent(_ firstLineHeadIndent: Double) // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional func setHeadIndent(_ headIndent: Double) // Paragraph head indent of the text (always 0 or positive).
    @objc optional func setUnderlined(_ underlined: Bool) // Is the first character underlined?
    @objc optional func setLineSpacing(_ lineSpacing: Double) // Line spacing of the text.
    @objc optional func setMultipleLineHeight(_ multipleLineHeight: Double) // Multiple line height of the text.
    @objc optional func setMaximumLineHeight(_ maximumLineHeight: Double) // Maximum line height of the text.
    @objc optional func setMinimumLineHeight(_ minimumLineHeight: Double) // Minimum line height of the text.
    @objc optional func setParagraphSpacing(_ paragraphSpacing: Double) // Paragraph spacing of the text.
    @objc optional func setSuperscript(_ superscript: Int) // The superscript level of the text.
    @objc optional func setTailIndent(_ tailIndent: Double) // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional func setTextContent(_ textContent: Any!) // The actual text content.
    @objc optional func setAlignment(_ alignment: DEVONthinkTextAlignment) // Alignment of the text.
    @objc optional func setURL(_ URL: Any!) // Link of the text.
}
extension SBObject: DEVONthinkCharacter {}

// MARK: DEVONthinkParagraph
@objc public protocol DEVONthinkParagraph: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func attachments() -> SBElementArray
    @objc optional func attributeRuns() -> SBElementArray
    @objc optional func characters() -> SBElementArray
    @objc optional func paragraphs() -> SBElementArray
    @objc optional func words() -> SBElementArray
    @objc optional var font: Any { get } // The name of the font of the first character.
    @objc optional var size: NSNumber { get } // The size in points of the first character.
    @objc optional var color: Any { get } // The color of the first character.
    @objc optional func setFont(_ font: Any!) // The name of the font of the first character.
    @objc optional func setSize(_ size: NSNumber!) // The size in points of the first character.
    @objc optional func setColor(_ color: Any!) // The color of the first character.
    @objc optional var baselineOffset: Double { get } // Number of points shifted above or below the normal baseline.
    @objc optional var background: Any { get } // The background color of the first character.
    @objc optional var firstLineHeadIndent: Double { get } // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional var headIndent: Double { get } // Paragraph head indent of the text (always 0 or positive).
    @objc optional var underlined: Bool { get } // Is the first character underlined?
    @objc optional var lineSpacing: Double { get } // Line spacing of the text.
    @objc optional var multipleLineHeight: Double { get } // Multiple line height of the text.
    @objc optional var maximumLineHeight: Double { get } // Maximum line height of the text.
    @objc optional var minimumLineHeight: Double { get } // Minimum line height of the text.
    @objc optional var paragraphSpacing: Double { get } // Paragraph spacing of the text.
    @objc optional var superscript: Int { get } // The superscript level of the text.
    @objc optional var tailIndent: Double { get } // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional var textContent: Any { get } // The actual text content.
    @objc optional var alignment: DEVONthinkTextAlignment { get } // Alignment of the text.
    @objc optional var URL: Any { get } // Link of the text.
    @objc optional func setBaselineOffset(_ baselineOffset: Double) // Number of points shifted above or below the normal baseline.
    @objc optional func setBackground(_ background: Any!) // The background color of the first character.
    @objc optional func setFirstLineHeadIndent(_ firstLineHeadIndent: Double) // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional func setHeadIndent(_ headIndent: Double) // Paragraph head indent of the text (always 0 or positive).
    @objc optional func setUnderlined(_ underlined: Bool) // Is the first character underlined?
    @objc optional func setLineSpacing(_ lineSpacing: Double) // Line spacing of the text.
    @objc optional func setMultipleLineHeight(_ multipleLineHeight: Double) // Multiple line height of the text.
    @objc optional func setMaximumLineHeight(_ maximumLineHeight: Double) // Maximum line height of the text.
    @objc optional func setMinimumLineHeight(_ minimumLineHeight: Double) // Minimum line height of the text.
    @objc optional func setParagraphSpacing(_ paragraphSpacing: Double) // Paragraph spacing of the text.
    @objc optional func setSuperscript(_ superscript: Int) // The superscript level of the text.
    @objc optional func setTailIndent(_ tailIndent: Double) // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional func setTextContent(_ textContent: Any!) // The actual text content.
    @objc optional func setAlignment(_ alignment: DEVONthinkTextAlignment) // Alignment of the text.
    @objc optional func setURL(_ URL: Any!) // Link of the text.
}
extension SBObject: DEVONthinkParagraph {}

// MARK: DEVONthinkWord
@objc public protocol DEVONthinkWord: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func attachments() -> SBElementArray
    @objc optional func attributeRuns() -> SBElementArray
    @objc optional func characters() -> SBElementArray
    @objc optional func paragraphs() -> SBElementArray
    @objc optional func words() -> SBElementArray
    @objc optional var font: Any { get } // The name of the font of the first character.
    @objc optional var size: NSNumber { get } // The size in points of the first character.
    @objc optional var color: Any { get } // The color of the first character.
    @objc optional func setFont(_ font: Any!) // The name of the font of the first character.
    @objc optional func setSize(_ size: NSNumber!) // The size in points of the first character.
    @objc optional func setColor(_ color: Any!) // The color of the first character.
    @objc optional var baselineOffset: Double { get } // Number of points shifted above or below the normal baseline.
    @objc optional var background: Any { get } // The background color of the first character.
    @objc optional var firstLineHeadIndent: Double { get } // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional var headIndent: Double { get } // Paragraph head indent of the text (always 0 or positive).
    @objc optional var underlined: Bool { get } // Is the first character underlined?
    @objc optional var lineSpacing: Double { get } // Line spacing of the text.
    @objc optional var multipleLineHeight: Double { get } // Multiple line height of the text.
    @objc optional var maximumLineHeight: Double { get } // Maximum line height of the text.
    @objc optional var minimumLineHeight: Double { get } // Minimum line height of the text.
    @objc optional var paragraphSpacing: Double { get } // Paragraph spacing of the text.
    @objc optional var superscript: Int { get } // The superscript level of the text.
    @objc optional var tailIndent: Double { get } // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional var textContent: Any { get } // The actual text content.
    @objc optional var alignment: DEVONthinkTextAlignment { get } // Alignment of the text.
    @objc optional var URL: Any { get } // Link of the text.
    @objc optional func setBaselineOffset(_ baselineOffset: Double) // Number of points shifted above or below the normal baseline.
    @objc optional func setBackground(_ background: Any!) // The background color of the first character.
    @objc optional func setFirstLineHeadIndent(_ firstLineHeadIndent: Double) // Paragraph first line head indent of the text (always 0 or positive)
    @objc optional func setHeadIndent(_ headIndent: Double) // Paragraph head indent of the text (always 0 or positive).
    @objc optional func setUnderlined(_ underlined: Bool) // Is the first character underlined?
    @objc optional func setLineSpacing(_ lineSpacing: Double) // Line spacing of the text.
    @objc optional func setMultipleLineHeight(_ multipleLineHeight: Double) // Multiple line height of the text.
    @objc optional func setMaximumLineHeight(_ maximumLineHeight: Double) // Maximum line height of the text.
    @objc optional func setMinimumLineHeight(_ minimumLineHeight: Double) // Minimum line height of the text.
    @objc optional func setParagraphSpacing(_ paragraphSpacing: Double) // Paragraph spacing of the text.
    @objc optional func setSuperscript(_ superscript: Int) // The superscript level of the text.
    @objc optional func setTailIndent(_ tailIndent: Double) // Paragraph tail indent of the text. If positive, it's the absolute line width. If 0 or negative, it's added to the line width.
    @objc optional func setTextContent(_ textContent: Any!) // The actual text content.
    @objc optional func setAlignment(_ alignment: DEVONthinkTextAlignment) // Alignment of the text.
    @objc optional func setURL(_ URL: Any!) // Link of the text.
}
extension SBObject: DEVONthinkWord {}

// MARK: DEVONthinkDatabase
@objc public protocol DEVONthinkDatabase: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func contents() -> SBElementArray
    @objc optional func parents() -> SBElementArray
    @objc optional func smartParents() -> SBElementArray
    @objc optional func tagGroups() -> SBElementArray
    @objc optional func id() -> Int // The scripting identifier of a database.
    @objc optional var uuid: Any { get } // The unique and persistent identifier of a database for external referencing.
    @objc optional var annotationsGroup: Any { get } // The group for annotations, will be created if necessary.
    @objc optional var comment: Any { get } // The comment of the database.
    @objc optional var currentGroup: Any { get } // The (selected) group of the frontmost window. Returns root if no current group exists.
    @objc optional var incomingGroup: Any { get } // The default group for new notes. Might be identical to root.
    @objc optional var encrypted: Bool { get } // Specifies if a database is encrypted or not.
    @objc optional var revisionProof: Bool { get } // Specifies if a database is revision-proof or not.
    @objc optional var readOnly: Bool { get } // Specifies if a database is read-only and can't be modified.
    @objc optional var SpotlightIndexing: Bool { get } // Specifies if Spotlight indexing of a database is en- or disabled.
    @objc optional var versioning: Bool { get } // Specifies whether versioning of documents is en- or disabled.
    @objc optional var name: String { get } // The name of the database.
    @objc optional var filename: Any { get } // The filename of the database.
    @objc optional var path: Any { get } // The POSIX path of the database.
    @objc optional var root: Any { get } // The top level group of the database.
    @objc optional var tagsGroup: Any { get } // The group for tags.
    @objc optional var trashGroup: Any { get } // The trash's group.
    @objc optional var versionsGroup: Any { get } // The group for versioning.
    @objc optional func setComment(_ comment: Any!) // The comment of the database.
    @objc optional func setSpotlightIndexing(_ SpotlightIndexing: Bool) // Specifies if Spotlight indexing of a database is en- or disabled.
    @objc optional func setVersioning(_ versioning: Bool) // Specifies whether versioning of documents is en- or disabled.
    @objc optional func setName(_ name: String!) // The name of the database.
}
extension SBObject: DEVONthinkDatabase {}

// MARK: DEVONthinkRecord
@objc public protocol DEVONthinkRecord: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func children() -> SBElementArray
    @objc optional func incomingReferences() -> SBElementArray
    @objc optional func incomingWikiReferences() -> SBElementArray
    @objc optional func outgoingReferences() -> SBElementArray
    @objc optional func outgoingWikiReferences() -> SBElementArray
    @objc optional func parents() -> SBElementArray
    @objc optional func id() -> Int // The scripting identifier of a record. Optimizing or closing a database might modify this identifier.
    @objc optional var MIMEType: Any { get } // The (proposed) MIME type of a record.
    @objc optional var uuid: Any { get } // The unique and persistent identifier of a record.
    @objc optional var additionDate: Any { get } // Date when the record was added to the database.
    @objc optional var aliases: Any { get } // Wiki aliases (separated by commas or semicolons) of a record.
    @objc optional var altitude: Double { get } // The altitude in metres of a record.
    @objc optional var annotation: Any { get } // Annotation of a record. Only plain & rich text and Markdown documents are supported. Read-only in case of revision-proof databases.
    @objc optional var annotationCount: Int { get } // The number of annotations. Supported by HTML pages, formatted notes, web archives, PDF, rich text & Markdown documents.
    @objc optional var attachedScript: Any { get } // POSIX path of script attached to a record.
    @objc optional var attachmentCount: Int { get } // The number of attachments. Currently only supported for RTFD documents and emails.
    @objc optional var attributesChangeDate: Any { get } // The change date of the record's attributes.
    @objc optional var batesNumber: Int { get } // Bates number.
    @objc optional var cells: [[Any]] { get } // The cells of a sheet. This is a list of rows, each row contains a list of string values for the various colums. Read-only in case of revision-proof databases.
    @objc optional var characterCount: Int { get } // The character count of a record.
    @objc optional var color: Any { get } // The color of a record. Currently only supported by tags & groups.
    @objc optional var columns: Any { get } // The column names of a sheet.
    @objc optional var comment: Any { get } // The comment of a record.
    @objc optional var contentHash: Any { get } // Stored SHA1 hash of files and document packages.
    @objc optional var creationDate: Any { get } // The creation date of a record. Read-only in case of revision-proof databases.
    @objc optional var customMetaData: Any { get } // User-defined metadata of a record as a dictionary containing key-value pairs. Setting a value for an unknown key automatically adds a definition to Settings > Data.
    @objc optional var data: Any { get } // The file data of a record. Currently only supported by PDF documents, images, rich text documents and web archives. Read-only in case of revision-proof databases.
    @objc optional var database: Any { get } // The database of the record.
    @objc optional var date: Any { get } // The (creation/modification) date of a record. Read-only in case of revision-proof databases.
    @objc optional var digitalObjectIdentifier: Any { get } // Digital object identifier (DOI) extracted from text of document, e.g. a scanned receipt, or from the title.
    @objc optional var dimensions: [NSNumber] { get } // The width and height of an image or PDF document in pixels or points.
    @objc optional var documentAmount: Any { get } // Amount extracted from text of document, e.g. a scanned receipt.
    @objc optional var documentDate: Any { get } // First date extracted from text of document, e.g. a scan.
    @objc optional var allDocumentDates: Any { get } // All dates extracted from text of document, e.g. a scan.
    @objc optional var documentName: Any { get } // Name based on text or properties of document
    @objc optional var dpi: NSNumber { get } // The resultion of an image in dpi.
    @objc optional var duplicates: Any { get } // The duplicates of a record (only other instances, not including the record).
    @objc optional var duration: Double { get } // The duration of audio and video files.
    @objc optional var encrypted: Bool { get } // Specifies if a document is encrypted or not. Currently only supported by PDF documents.
    @objc optional var excludeFromChat: Bool { get } // Exclude group or record from chat.
    @objc optional var excludeFromClassification: Bool { get } // Exclude group or record from classifying.
    @objc optional var excludeFromSearch: Bool { get } // Exclude group or record from searching.
    @objc optional var excludeFromSeeAlso: Bool { get } // Exclude record from see also.
    @objc optional var excludeFromTagging: Bool { get } // Exclude group from tagging.
    @objc optional var excludeFromWikiLinking: Bool { get } // Exclude record from automatic Wiki linking.
    @objc optional var filename: Any { get } // The current filename of a record.
    @objc optional var flag: Bool { get } // The flag of a record.
    @objc optional var geolocation: Any { get } // The human readable geogr. location of a record.
    @objc optional var height: NSNumber { get } // The height of an image or PDF document in pixels or points.
    @objc optional var image: Any { get } // The image or PDF document of a record. Setting supports both raw data and strings containing paths or URLs. Read-only in case of revision-proof databases.
    @objc optional var indexed: Bool { get } // Indexed or imported record.
    @objc optional var internationalStandardBookNumber: Any { get } // International standard book number (ISBN) extracted from text of document, e.g. a scanned receipt, or from the title.
    @objc optional var interval: Double { get } // Refresh interval of a feed. Currently overriden by settings.
    @objc optional var kind: Any { get } // The human readable and localized kind of a record. WARNING: Don't use this to check the type of a record, otherwise your script might fail depending on the version and the localization.
    @objc optional var label: Int { get } // Index of label (0-7) of a record.
    @objc optional var language: Any { get } // ISO code, e.g. 'en' or 'de', of language of document.
    @objc optional var latitude: Double { get } // The latitude in degrees of a record.
    @objc optional var location: Any { get } // The primary location of the record in the database as a POSIX path (/ in names is replaced with \/).
    @objc optional var locationGroup: Any { get } // The group of the record's primary location. This is identical to the first parent group.
    @objc optional var locationWithName: Any { get } // The full primary location of the record including its name (/ in names is replaced with \/).
    @objc optional var locking: Bool { get } // The locking of a record. Read-only in case of revision-proof databases.
    @objc optional var longitude: Double { get } // The longitude in degrees of a record.
    @objc optional var markdownSource: Any { get } // The Markdown source of a record if available or the record converted to Markdown if possible.
    @objc optional var metaData: Any { get } // Document metadata (e.g. of PDF & RTF documents, web pages or emails) of a record as a dictionary containing key-value pairs.
    @objc optional var modificationDate: Any { get } // The modification date of a record. Read-only in case of revision-proof databases.
    @objc optional var name: String { get } // The name of a record.
    @objc optional var nameWithoutDate: Any { get } // The name of a record without any dates.
    @objc optional var nameWithoutExtension: Any { get } // The name of a record without a file extension (independent of settings).
    @objc optional var newestDocumentDate: Any { get } // Newest date extracted from text of document, e.g. a scan.
    @objc optional var numberOfDuplicates: Int { get } // The number of duplicates of a record.
    @objc optional var numberOfHits: Int { get } // The number of hits of a record.
    @objc optional var numberOfReplicants: Int { get } // The number of replicants of a record.
    @objc optional var oldestDocumentDate: Any { get } // Oldest date extracted from text of document, e.g. a scan.
    @objc optional var originalName: String { get } // The original name of a record.
    @objc optional var openingDate: Any { get } // Date when a content was opened the last time or when a feed was refreshed the last time.
    @objc optional var pageCount: Int { get } // The page count of a record. Currently only supported by PDF documents.
    @objc optional var paginatedPDF: Any { get } // A printed/converted PDF of the record.
    @objc optional var path: Any { get } // The POSIX file path of a record. Only the path of external records can be changed. Not accessible at all in case of revision-proof databases.
    @objc optional var pending: Bool { get } // Flag whether the (latest) contents of a record haven't been downloaded from a sync location yet.
    @objc optional var plainText: Any { get } // The plain text of a record. Read-only in case of revision-proof databases. Setting this property of images, PDF documents, audio or video files sets the searchable, e.g. transcribed, text.
    @objc optional var proposedFilename: Any { get } // The proposed filename for a record.
    @objc optional var rating: Int { get } // Rating (0-5) of a record.
    @objc optional var recordType: DEVONthinkDataType { get } // The type of a record. WARNING: Don't use string conversions of this type for comparisons, this might fail due to known scripting issues of macOS.
    @objc optional var referenceURL: Any { get }
    @objc optional var reminder: Any { get } // Reminder of a record.
    @objc optional var richText: Any { get } // The rich text of the record (see extended text suite). Changes are only supported in case of RTF/RTFD documents and not by revision-proof databases.
    @objc optional var score: Double { get } // The score of the last comparison, classification or search (value between 0.0 and 1.0) or undefined otherwise.
    @objc optional var size: Int { get } // The size of a record in bytes.
    @objc optional var source: Any { get } // The HTML/XML source of a record if available or the record converted to HTML if possible. Read-only in case of revision-proof databases.
    @objc optional var tagType: DEVONthinkTagType { get } // The tag type of a record.
    @objc optional var tags: Any { get } // The tags of a record. Setting accepts both strings and parents.
    @objc optional var thumbnail: Any { get } // The thumbnail of a record. Setting supports both raw data and strings containing paths or URLs.
    @objc optional var unread: Bool { get } // The unread flag of a record.
    @objc optional var URL: Any { get } // The URL of a record. Read-only in case of bookmarks in revision-proof databases.
    @objc optional var webArchive: Any { get } // The web archive of a record if available or the record converted to web archive if possible.
    @objc optional var width: NSNumber { get } // The width of an image or PDF document in pixels or points.
    @objc optional var wordCount: Int { get } // The word count of a record.
    @objc optional func setAliases(_ aliases: Any!) // Wiki aliases (separated by commas or semicolons) of a record.
    @objc optional func setAltitude(_ altitude: Double) // The altitude in metres of a record.
    @objc optional func setAnnotation(_ annotation: Any!) // Annotation of a record. Only plain & rich text and Markdown documents are supported. Read-only in case of revision-proof databases.
    @objc optional func setAttachedScript(_ attachedScript: Any!) // POSIX path of script attached to a record.
    @objc optional func setAttributesChangeDate(_ attributesChangeDate: Any!) // The change date of the record's attributes.
    @objc optional func setBatesNumber(_ batesNumber: Int) // Bates number.
    @objc optional func setCells(_ cells: [[Any]]!) // The cells of a sheet. This is a list of rows, each row contains a list of string values for the various colums. Read-only in case of revision-proof databases.
    @objc optional func setColor(_ color: Any!) // The color of a record. Currently only supported by tags & groups.
    @objc optional func setComment(_ comment: Any!) // The comment of a record.
    @objc optional func setCreationDate(_ creationDate: Any!) // The creation date of a record. Read-only in case of revision-proof databases.
    @objc optional func setCustomMetaData(_ customMetaData: Any!) // User-defined metadata of a record as a dictionary containing key-value pairs. Setting a value for an unknown key automatically adds a definition to Settings > Data.
    @objc optional func setData(_ data: Any!) // The file data of a record. Currently only supported by PDF documents, images, rich text documents and web archives. Read-only in case of revision-proof databases.
    @objc optional func setDate(_ date: Any!) // The (creation/modification) date of a record. Read-only in case of revision-proof databases.
    @objc optional func setExcludeFromChat(_ excludeFromChat: Bool) // Exclude group or record from chat.
    @objc optional func setExcludeFromClassification(_ excludeFromClassification: Bool) // Exclude group or record from classifying.
    @objc optional func setExcludeFromSearch(_ excludeFromSearch: Bool) // Exclude group or record from searching.
    @objc optional func setExcludeFromSeeAlso(_ excludeFromSeeAlso: Bool) // Exclude record from see also.
    @objc optional func setExcludeFromTagging(_ excludeFromTagging: Bool) // Exclude group from tagging.
    @objc optional func setExcludeFromWikiLinking(_ excludeFromWikiLinking: Bool) // Exclude record from automatic Wiki linking.
    @objc optional func setFlag(_ flag: Bool) // The flag of a record.
    @objc optional func setGeolocation(_ geolocation: Any!) // The human readable geogr. location of a record.
    @objc optional func setImage(_ image: Any!) // The image or PDF document of a record. Setting supports both raw data and strings containing paths or URLs. Read-only in case of revision-proof databases.
    @objc optional func setInterval(_ interval: Double) // Refresh interval of a feed. Currently overriden by settings.
    @objc optional func setLabel(_ label: Int) // Index of label (0-7) of a record.
    @objc optional func setLatitude(_ latitude: Double) // The latitude in degrees of a record.
    @objc optional func setLocking(_ locking: Bool) // The locking of a record. Read-only in case of revision-proof databases.
    @objc optional func setLongitude(_ longitude: Double) // The longitude in degrees of a record.
    @objc optional func setModificationDate(_ modificationDate: Any!) // The modification date of a record. Read-only in case of revision-proof databases.
    @objc optional func setName(_ name: String!) // The name of a record.
    @objc optional func setNumberOfHits(_ numberOfHits: Int) // The number of hits of a record.
    @objc optional func setPath(_ path: Any!) // The POSIX file path of a record. Only the path of external records can be changed. Not accessible at all in case of revision-proof databases.
    @objc optional func setPlainText(_ plainText: Any!) // The plain text of a record. Read-only in case of revision-proof databases. Setting this property of images, PDF documents, audio or video files sets the searchable, e.g. transcribed, text.
    @objc optional func setRating(_ rating: Int) // Rating (0-5) of a record.
    @objc optional func setReminder(_ reminder: Any!) // Reminder of a record.
    @objc optional func setRichText(_ richText: Any!) // The rich text of the record (see extended text suite). Changes are only supported in case of RTF/RTFD documents and not by revision-proof databases.
    @objc optional func setSource(_ source: Any!) // The HTML/XML source of a record if available or the record converted to HTML if possible. Read-only in case of revision-proof databases.
    @objc optional func setTags(_ tags: Any!) // The tags of a record. Setting accepts both strings and parents.
    @objc optional func setThumbnail(_ thumbnail: Any!) // The thumbnail of a record. Setting supports both raw data and strings containing paths or URLs.
    @objc optional func setUnread(_ unread: Bool) // The unread flag of a record.
    @objc optional func setURL(_ URL: Any!) // The URL of a record. Read-only in case of bookmarks in revision-proof databases.
}
extension SBObject: DEVONthinkRecord {}

// MARK: DEVONthinkChild
@objc public protocol DEVONthinkChild: DEVONthinkRecord {
}
extension SBObject: DEVONthinkChild {}

// MARK: DEVONthinkContent
@objc public protocol DEVONthinkContent: DEVONthinkRecord {
}
extension SBObject: DEVONthinkContent {}

// MARK: DEVONthinkIncomingReference
@objc public protocol DEVONthinkIncomingReference: DEVONthinkRecord {
}
extension SBObject: DEVONthinkIncomingReference {}

// MARK: DEVONthinkIncomingWikiReference
@objc public protocol DEVONthinkIncomingWikiReference: DEVONthinkRecord {
}
extension SBObject: DEVONthinkIncomingWikiReference {}

// MARK: DEVONthinkOutgoingReference
@objc public protocol DEVONthinkOutgoingReference: DEVONthinkRecord {
}
extension SBObject: DEVONthinkOutgoingReference {}

// MARK: DEVONthinkOutgoingWikiReference
@objc public protocol DEVONthinkOutgoingWikiReference: DEVONthinkRecord {
}
extension SBObject: DEVONthinkOutgoingWikiReference {}

// MARK: DEVONthinkParent
@objc public protocol DEVONthinkParent: DEVONthinkRecord {
}
extension SBObject: DEVONthinkParent {}

// MARK: DEVONthinkReminder
@objc public protocol DEVONthinkReminder: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional var alarm: DEVONthinkReminderAlarm { get } // Alarm of reminder.
    @objc optional var alarmString: Any { get } // Name of sound, text to speak, text of alert/notification, source/path of script or recipient of email. Text can also contain placeholders.
    @objc optional var dayOfWeek: DEVONthinkReminderDay { get } // Scheduled day of week.
    @objc optional var dueDate: Any { get } // Due date.
    @objc optional var interval: Int { get } // Interval of schedule (every n hours, days, weeks, months or years)
    @objc optional var masc: Int { get } // Bitmap specifying scheduled days of week/month or scheduled months of year.
    @objc optional var schedule: DEVONthinkReminderSchedule { get } // Schedule of reminder.
    @objc optional var weekOfMonth: DEVONthinkReminderWeek { get } // Scheduled week of month.
    @objc optional func setAlarm(_ alarm: DEVONthinkReminderAlarm) // Alarm of reminder.
    @objc optional func setAlarmString(_ alarmString: Any!) // Name of sound, text to speak, text of alert/notification, source/path of script or recipient of email. Text can also contain placeholders.
    @objc optional func setDayOfWeek(_ dayOfWeek: DEVONthinkReminderDay) // Scheduled day of week.
    @objc optional func setDueDate(_ dueDate: Any!) // Due date.
    @objc optional func setInterval(_ interval: Int) // Interval of schedule (every n hours, days, weeks, months or years)
    @objc optional func setMasc(_ masc: Int) // Bitmap specifying scheduled days of week/month or scheduled months of year.
    @objc optional func setSchedule(_ schedule: DEVONthinkReminderSchedule) // Schedule of reminder.
    @objc optional func setWeekOfMonth(_ weekOfMonth: DEVONthinkReminderWeek) // Scheduled week of month.
}
extension SBObject: DEVONthinkReminder {}

// MARK: DEVONthinkSelectedRecord
@objc public protocol DEVONthinkSelectedRecord: DEVONthinkRecord {
}
extension SBObject: DEVONthinkSelectedRecord {}

// MARK: DEVONthinkSmartParent
@objc public protocol DEVONthinkSmartParent: DEVONthinkRecord {
    @objc optional var excludeSubgroups: Bool { get } // Exclude subgroups of the search group from searching.
    @objc optional var highlightOccurrences: Bool { get } // Highlight found occurrences in documents.
    @objc optional var searchGroup: Any { get } // Group of the smart group to search in.
    @objc optional var searchPredicates: Any { get } // A string representation of the conditions of the smart group.
    @objc optional func setExcludeSubgroups(_ excludeSubgroups: Bool) // Exclude subgroups of the search group from searching.
    @objc optional func setHighlightOccurrences(_ highlightOccurrences: Bool) // Highlight found occurrences in documents.
    @objc optional func setSearchGroup(_ searchGroup: Any!) // Group of the smart group to search in.
    @objc optional func setSearchPredicates(_ searchPredicates: Any!) // A string representation of the conditions of the smart group.
}
extension SBObject: DEVONthinkSmartParent {}

// MARK: DEVONthinkTagGroup
@objc public protocol DEVONthinkTagGroup: DEVONthinkParent {
}
extension SBObject: DEVONthinkTagGroup {}

// MARK: DEVONthinkTab
@objc public protocol DEVONthinkTab: SBObjectProtocol, DEVONthinkGenericMethods {
    @objc optional func id() -> Int // The unique identifier of the tab.
    @objc optional var PDF: Any { get } // A PDF without pagination of the visible document retaining the screen layout.
    @objc optional var webArchive: Any { get } // Web archive of the current web page.
    @objc optional var currentLine: Int { get } // Zero-based index of current line.
    @objc optional var currentMovieFrame: Any { get } // Image of current movie frame.
    @objc optional var currentTime: Double { get } // Time of current audio/video file.
    @objc optional var currentPage: Int { get } // Zero-based index of current PDF page.
    @objc optional var database: Any { get } // The database of the tab.
    @objc optional var contentRecord: Any { get } // The record of the visible document.
    @objc optional var loading: Bool { get } // Specifies if the current web page is still loading.
    @objc optional var numberOfColumns: Int { get } // Number of columns of the current sheet.
    @objc optional var numberOfRows: Int { get } // Number of rows of the current sheet.
    @objc optional var paginatedPDF: Any { get } // A printed PDF with pagination of the visible document.
    @objc optional var referenceURL: Any { get }
    @objc optional var selectedColumn: Int { get } // Index (1...n) of selected column of the current sheet.
    @objc optional var selectedColumns: [NSNumber] { get } // Indices (1...n) of selected columns of the current sheet.
    @objc optional var selectedRow: Int { get } // Index (1...n) of selected row of the current sheet.
    @objc optional var selectedRows: [NSNumber] { get } // Indices (1...n) of selected rows of the current sheet.
    @objc optional var source: Any { get } // The HTML source of the current web page.
    @objc optional var thinkWindow: Any { get } // The think window of the tab.
    @objc optional var URL: Any { get } // The URL of the current web page. In addition, setting the URL can be used to load a web page.
    @objc optional var selectedText: Any { get } // The rich text for the selection of the tab. Returns an empty string in case of no selection. Setting supports both text- and web-based documents, e.g. plain/rich text, Markdown documents or formatted notes. In addition, Markdown & HTML formatted input is supported too.
    @objc optional var plainText: Any { get } // The plain text of the tab.
    @objc optional var richText: Any { get } // The rich text of the tab. Changes are only supported in case of RTF/RTFD documents. In addition, Markdown & HTML formatted input is supported too.
    @objc optional func setCurrentTime(_ currentTime: Double) // Time of current audio/video file.
    @objc optional func setCurrentPage(_ currentPage: Int) // Zero-based index of current PDF page.
    @objc optional func setSelectedColumn(_ selectedColumn: Int) // Index (1...n) of selected column of the current sheet.
    @objc optional func setSelectedRow(_ selectedRow: Int) // Index (1...n) of selected row of the current sheet.
    @objc optional func setURL(_ URL: Any!) // The URL of the current web page. In addition, setting the URL can be used to load a web page.
    @objc optional func setSelectedText(_ selectedText: Any!) // The rich text for the selection of the tab. Returns an empty string in case of no selection. Setting supports both text- and web-based documents, e.g. plain/rich text, Markdown documents or formatted notes. In addition, Markdown & HTML formatted input is supported too.
    @objc optional func setRichText(_ richText: Any!) // The rich text of the tab. Changes are only supported in case of RTF/RTFD documents. In addition, Markdown & HTML formatted input is supported too.
}
extension SBObject: DEVONthinkTab {}

// MARK: DEVONthinkThinkWindow
@objc public protocol DEVONthinkThinkWindow: DEVONthinkWindow {
    @objc optional func tabs() -> SBElementArray
    @objc optional var PDF: Any { get } // A PDF without pagination of the visible document retaining the screen layout.
    @objc optional var webArchive: Any { get } // Web archive of the current web page.
    @objc optional var currentLine: Int { get } // Zero-based index of current line.
    @objc optional var currentMovieFrame: Any { get } // Image of current movie frame.
    @objc optional var currentTime: Double { get } // Time of current audio/video file.
    @objc optional var currentPage: Int { get } // Zero-based index of current PDF page.
    @objc optional var currentTab: Any { get } // The selected tab of the think window.
    @objc optional var database: Any { get } // The database of the window.
    @objc optional var contentRecord: Any { get } // The record of the visible document.
    @objc optional var loading: Bool { get } // Specifies if the current web page is still loading.
    @objc optional var numberOfColumns: Int { get } // Number of columns of the current sheet.
    @objc optional var numberOfRows: Int { get } // Number of rows of the current sheet.
    @objc optional var paginatedPDF: Any { get } // A printed PDF with pagination of the visible document.
    @objc optional var referenceURL: Any { get }
    @objc optional var selectedColumn: Int { get } // Index (1...n) of selected column of the current sheet.
    @objc optional var selectedColumns: [NSNumber] { get } // Indices (1...n) of selected columns of the current sheet.
    @objc optional var selectedRow: Int { get } // Index (1...n) of selected row of the current sheet.
    @objc optional var selectedRows: [NSNumber] { get } // Indices (1...n) of selected rows of the current sheet.
    @objc optional var source: Any { get } // The HTML source of the current web page.
    @objc optional var URL: Any { get } // The URL of the current web page. In addition, setting the URL can be used to load a web page.
    @objc optional var selectedText: Any { get } // The rich text for the selection of the window. Returns an empty string in case of no selection or missing value in case of no tab/document. Setting supports both text- and web-based documents, e.g. plain/rich text, Markdown documents or formatted notes. In addition, Markdown & HTML formatted input is supported too.
    @objc optional var plainText: Any { get } // The plain text of the window.
    @objc optional var richText: Any { get } // The rich text of the window. Changes are only supported in case of RTF/RTFD documents. In addition, Markdown & HTML formatted input is supported too.
    @objc optional func setCurrentTime(_ currentTime: Double) // Time of current audio/video file.
    @objc optional func setCurrentPage(_ currentPage: Int) // Zero-based index of current PDF page.
    @objc optional func setCurrentTab(_ currentTab: Any!) // The selected tab of the think window.
    @objc optional func setSelectedColumn(_ selectedColumn: Int) // Index (1...n) of selected column of the current sheet.
    @objc optional func setSelectedRow(_ selectedRow: Int) // Index (1...n) of selected row of the current sheet.
    @objc optional func setURL(_ URL: Any!) // The URL of the current web page. In addition, setting the URL can be used to load a web page.
    @objc optional func setSelectedText(_ selectedText: Any!) // The rich text for the selection of the window. Returns an empty string in case of no selection or missing value in case of no tab/document. Setting supports both text- and web-based documents, e.g. plain/rich text, Markdown documents or formatted notes. In addition, Markdown & HTML formatted input is supported too.
    @objc optional func setRichText(_ richText: Any!) // The rich text of the window. Changes are only supported in case of RTF/RTFD documents. In addition, Markdown & HTML formatted input is supported too.
}
extension SBObject: DEVONthinkThinkWindow {}

// MARK: DEVONthinkDocumentWindow
@objc public protocol DEVONthinkDocumentWindow: DEVONthinkThinkWindow {
    @objc optional var contentRecord: Any { get } // The record of the visible document.
    @objc optional func setContentRecord(_ contentRecord: Any!) // The record of the visible document.
}
extension SBObject: DEVONthinkDocumentWindow {}

// MARK: DEVONthinkMainWindow
@objc public protocol DEVONthinkMainWindow: DEVONthinkThinkWindow {
    @objc optional func selectedRecords() -> SBElementArray
    @objc optional var searchResults: Any { get } // The search results.
    @objc optional var root: Any { get } // The top level group of the window.
    @objc optional var searchQuery: Any { get } // The search query. Setting the query performs a search.
    @objc optional var selection: Any { get } // The current selection. 'selected records' element is recommended instead.
    @objc optional func setSearchResults(_ searchResults: Any!) // The search results.
    @objc optional func setRoot(_ root: Any!) // The top level group of the window.
    @objc optional func setSearchQuery(_ searchQuery: Any!) // The search query. Setting the query performs a search.
    @objc optional func setSelection(_ selection: Any!) // The current selection. 'selected records' element is recommended instead.
}
extension SBObject: DEVONthinkMainWindow {}

