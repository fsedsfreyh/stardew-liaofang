using System;
using System.IO;
using System.Text;

class Checker {
    static void Main() {
        var enc = new UTF8Encoding(false);
        var lines = File.ReadAllLines(@"D:\龙虾\projects\stardew-liaofang\scripts\ui\crafting_ui.gd", enc);
        for (int i = 155; i <= 162 && i < lines.Length; i++) {
            var l = lines[i];
            int tabs = 0;
            while (tabs < l.Length && l[tabs] == '\t') tabs++;
            Console.WriteLine($"L{i+1}: tabs={tabs} text=|{l.TrimStart()}|");
        }
    }
}
