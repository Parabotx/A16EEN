import QtQuick

// Starter dataset for recurring Ethiopian Orthodox monthly commemorations.
// Keep the historical/calendar facts here so the popup UI can grow separately.
QtObject {
    id: root

    readonly property int dataVersion: 1

    readonly property var monthlyCommemorations: ({
        "7": ({
            title: "ቅድስት ሥላሴ",
            category: "የሥላሴ መታሰቢያ",
            description: "በወሩ 7ኛው ቀን የቅድስት ሥላሴ መታሰቢያ ይከበራል።",
            verse: "በአብ፥ በወልድ፥ በመንፈስ ቅዱስም ስም አጥምቁአቸው።",
            reference: "ማቴዎስ 28፥19",
            reflection: "የእምነትን አንድነት እና የጥምቀትን ትርጉም ያስታውሳል።"
        }),
        "12": ({
            title: "ቅዱስ ሚካኤል",
            category: "የሊቀ መላእክት መታሰቢያ",
            description: "በወሩ 12ኛው ቀን ቅዱስ ሚካኤል ይታሰባል፤ የሰማያዊ ሰራዊት መሪነቱም ይዘከራል።",
            verse: "በሰማይም ሰልፍ ሆነ፤ ሚካኤልና መላእክቱ ዘንዶውን ተዋጉ።",
            reference: "ራእይ 12፥7",
            reflection: "የመጽሐፍ ቅዱሱ ንባብ የሚካኤልን በሰማይ ያደረገውን ውጊያ ያስታውሳል።"
        }),
        "16": ({
            title: "ኪዳነ ምሕረት",
            category: "ቅድስት ማርያም · የምሕረት ቃል ኪዳን",
            description: "ይህ ዕለት ቅድስት ማርያምን ከምሕረት እና ከምልጃ ጋር በተያያዘ የሚያስታውስ ወርሃዊ መታሰቢያ ነው።",
            verse: "ምሕረቱም ለሚፈሩት ከትውልድ እስከ ትውልድ ይኖራል።",
            reference: "ሉቃስ 1፥50",
            reflection: "የማርያም መዝሙር የእግዚአብሔርን ዘላለማዊ ምሕረት ያከብራል።"
        }),
        "19": ({
            title: "ቅዱስ ገብርኤል",
            category: "የመልአኩ መታሰቢያ",
            description: "በወሩ 19ኛው ቀን ቅዱስ ገብርኤል ይታሰባል፤ የብሥራቱም የመጽሐፍ ቅዱስ ታሪክ ይታሰባል።",
            verse: "ደስ ይበልሽ፥ ጸጋ የተሞላሽ፥ ጌታ ከአንቺ ጋር ነው።",
            reference: "ሉቃስ 1፥28",
            reflection: "የብሥራቱ ቃል በተስፋና በጸጋ የተሞላ ሰላምታ ነው።"
        }),
        "21": ({
            title: "ቅድስት ማርያም",
            category: "የእመቤታችን ወርሃዊ መታሰቢያ",
            description: "የወሩ 21ኛው ቀን በኢትዮጵያ ኦርቶዶክስ ትውፊት ለቅድስት ማርያም የተለየ ወርሃዊ መታሰቢያ ነው።",
            verse: "ከዛሬ ጀምሮ ትውልድ ሁሉ ምስጉን ይሉኛል።",
            reference: "ሉቃስ 1፥48",
            reflection: "ይህ ጥቅስ ማርያም በመድኃኒቷ እግዚአብሔር ያደረገላትን ታላቅ ነገር ስትመሰክር ከተናገረችው መዝሙር ነው።"
        }),
        "23": ({
            title: "ቅዱስ ጊዮርጊስ",
            category: "የቅዱሱ ወርሃዊ መታሰቢያ",
            description: "በብዙ የኢትዮጵያ ኦርቶዶክስ የወርሃዊ መታሰቢያ ዝርዝሮች 23ኛው ቀን ለቅዱስ ጊዮርጊስ ይሰጣል።",
            verse: "መልካሙን ገድል ተጋድዬአለሁ፥ ሩጫውን ጨርሻለሁ፥ ሃይማኖትን ጠብቄአለሁ።",
            reference: "2 ጢሞቴዎስ 4፥7",
            reflection: "ይህ ጥቅስ በእምነት ጽናትን ያስታውሳል፤ በቀጥታ ስለ ቅዱስ ጊዮርጊስ የተጻፈ አይደለም።"
        }),
        "24": ({
            title: "አቡነ ተክለ ሃይማኖት",
            category: "የአቡነ ተክለ ሃይማኖት መታሰቢያ",
            description: "በብዙ የኢትዮጵያ ኦርቶዶክስ የወርሃዊ መታሰቢያ ዝርዝሮች 24ኛው ቀን አቡነ ተክለ ሃይማኖትን ያስታውሳል።",
            verse: "በፊታችን የተደረገውን ሩጫ በትዕግሥት እንሩጥ።",
            reference: "ዕብራውያን 12፥1",
            reflection: "ይህ ጥቅስ በእምነት ጉዞ ውስጥ ጽናትና ትዕግሥት እንድንይዝ ያበረታታል።"
        }),
        "27": ({
            title: "የጌታችን ሞት መታሰቢያ",
            category: "የመስቀሉና የመዳናችን ማሰላሰያ",
            description: "በአንዳንድ የኢትዮጵያ የወርሃዊ መታሰቢያ ዝርዝሮች 27ኛው ቀን የጌታችንን ሞት ለማሰብ ይመደባል።",
            verse: "ተፈጸመ።",
            reference: "ዮሐንስ 19፥30",
            reflection: "የወንጌሉ ቃል የክርስቶስን የመስቀል ሥራ እንድናስብ ይጋብዘናል።"
        }),
        "29": ({
            title: "ልደተ ወልድ",
            category: "የክርስቶስ ልደት መታሰቢያ",
            description: "በወሩ 29ኛው ቀን የክርስቶስ ልደት በወርሃዊ መታሰቢያ ይታወሳል።",
            verse: "ዛሬ በዳዊት ከተማ አዳኝ ተወልዶላችኋል፤ እርሱም ክርስቶስ ጌታ ነው።",
            reference: "ሉቃስ 2፥11",
            reflection: "የመላእክቱ የልደት ምሥራች የአዳኙን መወለድ ያበስራል።"
        })
    })

    readonly property var fallbackCommemoration: ({
        title: "የዕለቱ መንፈሳዊ ማሰላሰያ",
        category: "የቀኑ ማሰላሰያ",
        description: "ይህ ቀን በሰላም፣ በጸሎት እና በመልካም ሥራ እንዲኖር ያስታውሰናል። ተጨማሪ የቀን መታሰቢያዎች በቀጣይ ዝማኔዎች ይጨመራሉ።",
        verse: "ይህ እግዚአብሔር ያደረገው ቀን ነው፤ በእርሱ ደስ ይበለን ሐሴትም እናድርግ።",
        reference: "መዝሙር 118፥24",
        reflection: "እያንዳንዱን ቀን በምስጋና እና በተስፋ ለመቀበል የሚረዳ ቃል።"
    })

    function forDay(day) {
        return root.monthlyCommemorations[String(day)] || root.fallbackCommemoration
    }
}
