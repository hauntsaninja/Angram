import Cocoa

class Controller: NSObject {

    @IBOutlet var plainField: NSTextView!
    @IBOutlet var gramField: NSTextView!
    @IBOutlet var partField: NSTextView!

    var gramLimit = 1000 as Int32
    var timeLimit = 3 as Double
    var exclude = "" as String

    var subFilt = ""
    var subUse = ""

    @IBOutlet weak var subTableDel: SubTableDel!
    @IBOutlet weak var statTableDel: StatTableDel!

    var subanagramQueue: OperationQueue
    var anagramQueue: OperationQueue

    override init() {
        subanagramQueue = OperationQueue()
        anagramQueue = OperationQueue()
        super.init()
    }

    override func awakeFromNib() {
        let f = NSFont.systemFont(ofSize: 13)
        plainField.font = f
        gramField.font = f
        partField.font = f
    }

    @IBAction func setDict(_ sender: NSSlider) {
        GramTools.buildDict(Int32(sender.integerValue));
        subanagramInput()
    }

    @IBAction func anagramInput(_ sender: NSButton) {
        partField.string = ""
        anagramQueue.cancelAllOperations()

        if sender.title != "Find!" {
            sender.title = "Find!"
            return
        }
        sender.title = "Stop."

        let p = plainField.string
        let g = gramField.string
        let op = BlockOperation()
        unowned let weakop = op
        op.addExecutionBlock({ () -> Void in
            let list = GramTools.anagram(withPlain: p, gram:g, op:weakop, exclude:self.exclude, gramLimit:self.gramLimit, timeLimit:self.timeLimit)
            if weakop.isCancelled {return}
            self.performSelector(onMainThread: #selector(Controller.anagramOutput(_:)), with:list, waitUntilDone:false)
            sender.performSelector(onMainThread: #selector(setter: NSUserActivity.title), with:"Find!", waitUntilDone:false)
        })
        anagramQueue.addOperation(op)
    }

    func anagramOutput(_ list: [String]) {
        if list.count > 0 {
            var text = ""
            for anagram in list {
                text += anagram + "\n"
            }
            partField.string = text
        }
        else if plainField.string == "abcdefghijklmnopqrstuvwxyz" && gramField.string == "" {
            partField.string = "-- http://clagnut.com/blog/2380/ --"
        }
        else {
            partField.string = "-- no anagrams found 😥 --"
        }
    }

    func subanagramOutput(_ data: [[String]]) {
        subTableDel.setData(data, plain: plainField.string!, gram: gramField.string!)
    }

    func subanagramInput() {
        let p = plainField.string
        let g = gramField.string
        let f = subFilt
        let u = subUse
        subanagramQueue.cancelAllOperations()
        let op = BlockOperation()
        unowned let weakop = op
        op.addExecutionBlock({ () -> Void in
            usleep(30000);
            if weakop.isCancelled {return}
            let data = GramTools.subanagram(withPlain: p, gram:g, filter:f, use:u)
            if weakop.isCancelled {return}
            self.performSelector(onMainThread: #selector(Controller.subanagramOutput(_:)), with:data, waitUntilDone:false)
        })
        subanagramQueue.addOperation(op)
    }

    func textDidChange(_ notif: Notification) {
        let p = plainField.string
        let g = gramField.string
        let cmp = GramTools.cmp(withPlain: p, gram: g)
        if p == "" && g == "" {
            subanagramOutput([[String]]())
            gramField.backgroundColor = NSColor.white
        } else if cmp < 0 {
            subanagramInput()
            gramField.backgroundColor = NSColor.white
        } else if cmp == 0 {
            subanagramOutput([[String]]())
            gramField.backgroundColor = NSColor.green.withAlphaComponent(0.2)
        } else if cmp > 0 {
            subanagramOutput([[String]]())
            gramField.backgroundColor = NSColor.red.withAlphaComponent(0.2)
        }
        gramField.display()

        let stats = GramTools.stats(withPlain: p, gram: g)
        statTableDel.setData(stats!)
    }

    override func controlTextDidChange(_ notif: Notification) {
        subanagramInput()
    }

    func textView(_ tv: NSTextView, doCommandBySelector selec:Selector) -> Bool {
        if selec == #selector(NSResponder.insertTab(_:)) {
            tv.window?.selectNextKeyView(nil);
            return true
        }
        if selec == #selector(NSResponder.insertBacktab(_:)) {
            tv.window?.selectPreviousKeyView(nil)
            return true
        }
        return false
    }
}

// Delegate for the table that shows the subanagrams
class SubTableDel: NSObject {

    @IBOutlet weak var subTable: NSTableView!
    var subData = [[String]]()
    var plain = ""
    var gram = ""

    override func awakeFromNib() {
        subTable.removeTableColumn(subTable.tableColumns.last!)
        subTable.reloadData()
    }

    func setData(_ data: [[String]], plain: String, gram: String) {
        subData = data
        self.plain = plain
        self.gram = gram
        while subTable.tableColumns.count < subData.count {
            let tableColumn = NSTableColumn(identifier: "\(subTable.tableColumns.count)")
            tableColumn.title = String(repeating: String(("W" as Character)), count: 1 + max(2, subTable.tableColumns.count))
            tableColumn.sizeToFit()
            subTable.addTableColumn(tableColumn)
        }
        subTable.reloadData()
    }

    func numberOfRowsInTableView(_ tableView: NSTableView) -> Int {
        var ret = 0
        for col in subData {
            ret = max(ret, col.count)
        }
        return min(500, ret)
    }

    func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var result = tableView.make(withIdentifier: "second", owner:self) as? NSTextField
        if result == nil {
            result = NSTextField(frame: NSRect(x: 0, y: 0, width: tableColumn!.width, height: 10))
            result!.identifier = "second";
            result!.isBezeled = false
            result!.isEditable = false
            result!.alignment = NSLeftTextAlignment
        }
        result!.backgroundColor = NSColor.clear
        let columnID = Int(tableColumn!.identifier)
        if columnID! < subData.count && row < subData[columnID!].count {
            result!.stringValue = subData[columnID!][row]
            if GramTools.doesSubanagramComplete(subData[columnID!][row], plain: plain, gram: gram) {
                result!.backgroundColor = NSColor.green.withAlphaComponent(0.2)
            }
        }
        else {
            result!.stringValue = "~"
        }
        return result;
    }
}

// Delegate for the table that shows the letter statistics
class StatTableDel: NSObject {

    let frequencyOrdered = "ETAOINSHRDLCUMWFGYPBVKJXQZ"
    let naturalFrequencies = [
        "E":12.702, "T":9.056, "A":8.167, "O":7.507, "I":6.966, "N":6.749,
        "S":6.327, "H":6.094, "R":5.987, "D":4.253, "L":4.025, "C":2.782, "U":2.758,
        "M":2.406, "W":2.361, "F":2.228, "G":2.015, "Y":1.974, "P":1.929, "B":1.492,
        "V":0.978, "K":0.772, "J":0.153, "X":0.150, "Q":0.095, "Z":0.074
    ]

    @IBOutlet weak var statTable: NSTableView!
    var totalCount = 0
    var statData = [String: NSNumber]()

    override func awakeFromNib() {
        statTable.removeTableColumn(statTable.tableColumns.last!)
        let tableColumn = NSTableColumn(identifier: "vowel_pct")
        tableColumn.title = String("Vowel %")
        tableColumn.width = 70
        tableColumn.headerCell.alignment = NSCenterTextAlignment
        statTable.addTableColumn(tableColumn)
        for char in frequencyOrdered.characters {
            let s = String(char)
            let tableColumn = NSTableColumn(identifier: s)
            tableColumn.title = String(s)
            tableColumn.width = 20
            tableColumn.headerCell.alignment = NSCenterTextAlignment
            statTable.addTableColumn(tableColumn)
        }
        statTable.reloadData()
    }

    func resizeCols() {
        for col in 0 ..< statTable.tableColumns.count {
            let tableColumn = statTable.tableColumns[col]
            if tableColumn.identifier == "vowel_pct" {
                tableColumn.width = 70
                continue
            }
            let count = statData[tableColumn.identifier]
            if count != nil && count!.intValue >= 20 {
                tableColumn.width = 40
            } else {
                tableColumn.width = 20
            }
        }
        statTable.display()
    }

    func setData(_ data: [String: NSNumber]) {
        var data = data

        totalCount = 0
        for char in frequencyOrdered.characters {
            totalCount += (data[String(char)]?.intValue)!
        }
        var vowelCount = 0
        for char in "AEIOU".characters {
            vowelCount += (data[String(char)]?.intValue)!
        }
        data["vowel_pct"] = totalCount == 0 ? NSNumber(value: 0) : NSNumber(value: round(Float(1000 * vowelCount) / Float(totalCount)) / 10)

        statData = data
        resizeCols()
        statTable.reloadData()
    }

    func selectionShouldChangeInTableView(_: NSTableView) -> Bool {
        return false
    }

    func numberOfRowsInTableView(_ tableView: NSTableView) -> Int {
        return 1
    }

    func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var result = tableView.make(withIdentifier: "silly", owner:self) as? NSTextField
        if result == nil {
            result = NSTextField(frame: NSRect(x: 0, y: 0, width: tableColumn!.width, height: 10))
            result!.identifier = "silly";
            result!.isBezeled = false
            result!.isEditable = false
            result!.isSelectable = false
            result!.alignment = NSCenterTextAlignment
            result!.font = NSFont.systemFont(ofSize: 10)
        }

        let columnID = tableColumn!.identifier
        let count = statData[columnID]
        if totalCount == 0 {
            result!.stringValue = "0"
            result!.backgroundColor = NSColor.white
        } else if count != nil {
            let val = count!.intValue
            result!.stringValue = "\(val)"

            // do something complicated to colour the cells
            if columnID == "vowel_pct" {
                let a = Double(max(-20, min(20, val - 40))) / 20.0
                let b = CGFloat(a*a)
                result!.backgroundColor = (a < 0 ? NSColor.red : NSColor.blue).withAlphaComponent(0.5 * b)
            } else {
                let a = naturalFrequencies[columnID]! * Double(totalCount) / 100.0
                let b = 1 - Double(val) / a
                let c = CGFloat(pow(b/(b < 0 ? 2 : 1.4), 2))
                result!.backgroundColor = (b < 0 ? NSColor.red : NSColor.blue).withAlphaComponent(0.5 * c)
            }
        }
        return result;
    }
}
