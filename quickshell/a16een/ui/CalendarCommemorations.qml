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
            description: "ቅድስት ሥላሴ የክርስቲያናዊ እምነት ማዕከል ናት። ይህ መታሰቢያ አብን፣ ወልድን እና መንፈስ ቅዱስን በአንድነት ለማሰብ ይጋብዛል።",
            verse: "በአብ፥ በወልድ፥ በመንፈስ ቅዱስም ስም አጥምቁአቸው።",
            reference: "ማቴዎስ 28፥19",
            reflection: "የእምነትን አንድነት እና የጥምቀትን ትርጉም ያስታውሳል።"
        }),
        "12": ({
            title: "ቅዱስ ሚካኤል",
            category: "የሊቀ መላእክት መታሰቢያ",
            image: "saint-michael.webp",
            description: "ቅዱስ ሚካኤል የሰማያዊ ሰራዊት መሪ እና የጽድቅ ተሟጋች ሆኖ ይታወሳል። መታሰቢያው በእምነትና በመንፈሳዊ ጥንካሬ እንድንቆም ያስታውሰናል።",
            verse: "በሰማይም ሰልፍ ሆነ፤ ሚካኤልና መላእክቱ ዘንዶውን ተዋጉ።",
            reference: "ራእይ 12፥7",
            reflection: "የመጽሐፍ ቅዱሱ ንባብ የሚካኤልን በሰማይ ያደረገውን ውጊያ ያስታውሳል።"
        }),
        "16": ({
            title: "ኪዳነ ምሕረት",
            category: "ቅድስት ማርያም · የምሕረት ቃል ኪዳን",
            imagePool: "kidane-mehret", image: "kidane-mehret.webp",
            description: "ኪዳነ ምሕረት ቅድስት ማርያም ለምእመናን የምሕረትና የምልጃ ተስፋ መሆኗን የሚያስታውስ መታሰቢያ ነው።",
            verse: "ምሕረቱም ለሚፈሩት ከትውልድ እስከ ትውልድ ይኖራል።",
            reference: "ሉቃስ 1፥50",
            reflection: "የማርያም መዝሙር የእግዚአብሔርን ዘላለማዊ ምሕረት ያከብራል።"
        }),
        "19": ({
            title: "ቅዱስ ገብርኤል",
            category: "የመልአኩ መታሰቢያ",
            description: "ቅዱስ ገብርኤል የመልእክት አቀባይ መልአክ ሆኖ ይታወቃል። የብሥራቱ ታሪክ ተስፋንና የእግዚአብሔርን ቃል ያስታውሳል።",
            verse: "ደስ ይበልሽ፥ ጸጋ የተሞላሽ፥ ጌታ ከአንቺ ጋር ነው።",
            reference: "ሉቃስ 1፥28",
            reflection: "የብሥራቱ ቃል በተስፋና በጸጋ የተሞላ ሰላምታ ነው።"
        }),
        "21": ({
            title: "ቅድስት ማርያም",
            category: "የእመቤታችን ወርሃዊ መታሰቢያ",
            imagePool: "saint-mary", image: "saint-mary.webp",
            description: "ቅድስት ማርያም በእምነት፣ በትሕትና እና በመታዘዝ ምሳሌ ሆና ትታወሳለች። መታሰቢያዋ የእመቤታችንን ፍቅርና ምልጃ ለማሰብ ይጋብዛል።",
            verse: "ከዛሬ ጀምሮ ትውልድ ሁሉ ምስጉን ይሉኛል።",
            reference: "ሉቃስ 1፥48",
            reflection: "ይህ ጥቅስ ማርያም በመድኃኒቷ እግዚአብሔር ያደረገላትን ታላቅ ነገር ስትመሰክር ከተናገረችው መዝሙር ነው።"
        }),
        "23": ({
            title: "ቅዱስ ጊዮርጊስ",
            category: "የቅዱሱ ወርሃዊ መታሰቢያ",
            description: "ቅዱስ ጊዮርጊስ በእምነቱ ጽናትና በድፍረቱ የሚታወስ ሰማዕት ነው። ታሪኩ በመከራ ውስጥ ታማኝነትን እና ጽናትን ያስተምራል።",
            verse: "መልካሙን ገድል ተጋድዬአለሁ፥ ሩጫውን ጨርሻለሁ፥ ሃይማኖትን ጠብቄአለሁ።",
            reference: "2 ጢሞቴዎስ 4፥7",
            reflection: "ይህ ጥቅስ በእምነት ጽናትን ያስታውሳል፤ በቀጥታ ስለ ቅዱስ ጊዮርጊስ የተጻፈ አይደለም።"
        }),
        "24": ({
            title: "አቡነ ተክለ ሃይማኖት",
            category: "የአቡነ ተክለ ሃይማኖት መታሰቢያ",
            description: "አቡነ ተክለ ሃይማኖት በጸሎት፣ በትሕትና እና በመንፈሳዊ ትጋት የሚታወሱ የኢትዮጵያ ቅዱስ አባት ናቸው።",
            verse: "በፊታችን የተደረገውን ሩጫ በትዕግሥት እንሩጥ።",
            reference: "ዕብራውያን 12፥1",
            reflection: "ይህ ጥቅስ በእምነት ጉዞ ውስጥ ጽናትና ትዕግሥት እንድንይዝ ያበረታታል።"
        }),
        "27": ({
            title: "የጌታችን ሞት መታሰቢያ",
            category: "የመስቀሉና የመዳናችን ማሰላሰያ",
            description: "ይህ መታሰቢያ የክርስቶስን መስቀላዊ መስዋዕትነት እና ለሰው ልጆች ያለውን ፍቅር ለማሰላሰል ይጋብዛል።",
            verse: "ተፈጸመ።",
            reference: "ዮሐንስ 19፥30",
            reflection: "የወንጌሉ ቃል የክርስቶስን የመስቀል ሥራ እንድናስብ ይጋብዘናል።"
        }),
        "29": ({
            title: "ልደተ ወልድ",
            category: "የክርስቶስ ልደት መታሰቢያ",
            description: "የክርስቶስ ልደት የተስፋ፣ የትሕትና እና የመዳን መልእክት ያስታውሳል፤ እግዚአብሔር ወደ ዓለም በሰውነት መምጣቱን ይዘክራል።",
            verse: "ዛሬ በዳዊት ከተማ አዳኝ ተወልዶላችኋል፤ እርሱም ክርስቶስ ጌታ ነው።",
            reference: "ሉቃስ 2፥11",
            reflection: "የመላእክቱ የልደት ምሥራች የአዳኙን መወለድ ያበስራል።"
        })
    })

    // Annual observances live separately from monthly day-of-month commemorations.
    // Ethiopian dates are converted for each Ethiopian year; fixed civil dates and
    // movable Orthodox feasts are calculated for each Gregorian year.
    readonly property var annualFeasts: [
        {
            id: "enkutatash", calendar: "ethiopian", month: 1, day: 1,
            title: "እንቁጣጣሽ", category: "የኢትዮጵያ አዲስ ዓመት",
            description: "የኢትዮጵያ አዲስ ዓመት፤ አዲስ ዘመንን በተስፋ እና በምስጋና የምንቀበልበት ቀን።",
            verse: "ዓመትን በቸርነትህ አክሊል ታቀዳጃለህ።",
            reference: "መዝሙር 65፥11",
            reflection: "መልካም አዲስ ዓመት፤ በሰላም፣ በጤና እና በበረከት የተሞላ ዘመን ይሁን።"
        },
        {
            id: "meskel", calendar: "ethiopian", month: 1, day: 17,
            title: "መስቀል", category: "ሃይማኖታዊ እና ሀገራዊ በዓል",
            description: "የእውነተኛው መስቀል መገኘትን የሚያስታውስ ታዋቂ የኢትዮጵያ በዓል።",
            verse: "እኔ ግን በጌታችን በኢየሱስ ክርስቶስ መስቀል እንጂ በሌላ እንዳልመካ አይሁን።",
            reference: "ገላትያ 6፥14",
            reflection: "መስቀል የክርስቲያናዊ እምነትን፣ ተስፋን እና መዳንን ያስታውሳል።"
        },
        {
            id: "mikael-hidar", calendar: "ethiopian", month: 3, day: 12,
            image: "saint-michael.webp",
            title: "ሕዳር ሚካኤል", category: "የቅዱስ ሚካኤል ታላቅ ዓመታዊ በዓል",
            description: "ሕዳር 12 የቅዱስ ሚካኤል ዓመታዊ መታሰቢያ ሲሆን፣ ቅዱሱ በሰማያዊ ሰራዊት መሪነቱ እና በእምነት ጽናት ምሳሌነቱ ይታወሳል።",
            verse: "በሰማይም ሰልፍ ሆነ፤ ሚካኤልና መላእክቱ ዘንዶውን ተዋጉ።",
            reference: "ራእይ 12፥7",
            reflection: "የቅዱስ ሚካኤል ዓመታዊ መታሰቢያ በሕዳር 12 ይከበራል።"
        },
        {
            id: "elias-tahsas", calendar: "ethiopian", month: 4, day: 1,
            title: "ቅዱስ ኤልያስ", category: "የነቢዩ ኤልያስ መታሰቢያ",
            description: "ታኅሣሥ 1 በወርሃዊ መታሰቢያ ዝርዝሮች ከነቢዩ ኤልያስ ጋር ይያያዛል።",
            verse: "ከዚያ በኋላ ገር ያለ ድምፅ ሰማ።",
            reference: "1 ነገሥት 19፥12",
            reflection: "ይህ የኤልያስ ታሪክ ጥቅስ እግዚአብሔር በጸጥታ የሚገለጥበትን አፍታ ያስታውሳል።"
        },
        {
            id: "genna", calendar: "ethiopian", month: 4, day: 29,
            title: "ገና", category: "የክርስቶስ ልደት · ሀገራዊ በዓል",
            description: "የኢየሱስ ክርስቶስ ልደት በዓል፤ በኢትዮጵያ ታኅሣሥ 29 ይከበራል።",
            verse: "ዛሬ በዳዊት ከተማ አዳኝ ተወልዶላችኋል፤ እርሱም ክርስቶስ ጌታ ነው።",
            reference: "ሉቃስ 2፥11",
            reflection: "የልደት ምሥራች ሰላምን፣ ተስፋን እና ደስታን ያስታውሳል።"
        },
        {
            id: "timkat", calendar: "ethiopian", month: 5, day: 11,
            title: "ጥምቀት", category: "የጥምቀት በዓል · ሀገራዊ በዓል",
            description: "የኢየሱስ ክርስቶስን ጥምቀት የሚያስታውስ የኢትዮጵያ ታዋቂ በዓል።",
            verse: "ይህ የምወደው ልጄ ነው፥ በእርሱ ደስ ብሎኛል።",
            reference: "ማቴዎስ 3፥17",
            reflection: "የጥምቀት በዓል የክርስቶስን ጥምቀት እና የሥላሴን መገለጥ ያስታውሳል።"
        },
        {
            id: "adwa", calendar: "gregorian", month: 3, day: 2,
            title: "የአድዋ ድል በዓል", category: "ሀገራዊ በዓል",
            description: "በአድዋ የተገኘውን የኢትዮጵያ ድል እና የነፃነት ታሪክ የሚያስታውስ በዓል።",
            verse: "እርስ በርሳችሁ ተባበሩ፥ አንድ ልብና አንድ አሳብ ይኑራችሁ።",
            reference: "ፊልጵስዩስ 2፥2",
            reflection: "ይህ በዓል አንድነትን፣ ድፍረትን እና የሀገር ነፃነትን ያስታውሳል።"
        },
        {
            id: "kidane-mihret-yekatit", calendar: "ethiopian", month: 6, day: 16,
            imagePool: "kidane-mehret", image: "kidane-mehret.webp",
            title: "የካቲት ኪዳነ ምሕረት", category: "የቅድስት ማርያም ዓመታዊ መታሰቢያ",
            description: "የካቲት 16 የኪዳነ ምሕረት መታሰቢያ የቅድስት ማርያምን ምልጃና ለምእመናን የምሕረት ተስፋ ያከብራል።",
            verse: "ምሕረቱም ለሚፈሩት ከትውልድ እስከ ትውልድ ይኖራል።",
            reference: "ሉቃስ 1፥50",
            reflection: "ይህ ጥቅስ በማርያም የምስጋና መዝሙር ውስጥ የተገለጸውን የእግዚአብሔር ምሕረት ያስታውሳል።"
        },
        {
            id: "labour-day", calendar: "gregorian", month: 5, day: 1,
            title: "የሠራተኞች ቀን", category: "ሀገራዊ እና ዓለም አቀፍ መታሰቢያ",
            description: "የሠራተኞችን አስተዋጽኦ እና የፍትሐዊ የሥራ ሁኔታዎችን የሚያስታውስ ቀን።",
            verse: "ሠራተኛ ደመወዙን ሊቀበል ይገባዋል።",
            reference: "1 ጢሞቴዎስ 5፥18",
            reflection: "ሥራን በክብር ማየትን እና ለሠራተኞች ፍትሕን ያስታውሳል።"
        },
        {
            id: "patriots-victory", calendar: "gregorian", month: 5, day: 5,
            title: "የአርበኞች ድል ቀን", category: "ሀገራዊ በዓል",
            description: "በኢትዮጵያ ታሪክ ውስጥ የአርበኞችን ትጋት እና ድል የሚያስታውስ ቀን።",
            verse: "ለነፃነት ጠርቶአችኋልና፤ በነፃነት ጽኑ።",
            reference: "ገላትያ 5፥1",
            reflection: "የአርበኞችን መስዋዕትነት እና የነፃነትን ዋጋ ያስታውሳል።"
        },
        {
            id: "lideta-ginbot", calendar: "ethiopian", month: 9, day: 1,
            imagePool: "saint-mary", image: "saint-mary.webp",
            title: "ልደታ ለማርያም", category: "የቅድስት ማርያም ዓመታዊ በዓል",
            description: "ልደታ ለማርያም የእመቤታችንን ልደት የሚያከብር በዓል ነው። መታሰቢያው ለማርያም የተሰጠውን ክብር እና በቤተክርስቲያን ትውፊት ያላትን ልዩ ስፍራ ያስታውሳል።",
            verse: "ከዛሬ ጀምሮ ትውልድ ሁሉ ምስጉን ይሉኛል።",
            reference: "ሉቃስ 1፥48",
            reflection: "ይህ ጥቅስ በማርያም የምስጋና መዝሙር ውስጥ ይገኛል።"
        },
        {
            id: "mikael-sene", calendar: "ethiopian", month: 10, day: 12,
            image: "saint-michael.webp",
            title: "ሰኔ ሚካኤል", category: "የቅዱስ ሚካኤል ታላቅ ዓመታዊ በዓል",
            description: "ሰኔ 12 የቅዱስ ሚካኤልን መታሰቢያ በጸሎትና በምስጋና የምናከብርበት ቀን ነው። የቅዱሱ ታሪክ በእምነት ጽናትን ያበረታታል።",
            verse: "በሰማይም ሰልፍ ሆነ፤ ሚካኤልና መላእክቱ ዘንዶውን ተዋጉ።",
            reference: "ራእይ 12፥7",
            reflection: "ቅዱስ ሚካኤል በየወሩ 12ኛው ቀን ይታሰባል፤ ሕዳር 12 እና ሰኔ 12 ዋና ዓመታዊ በዓላቱ ናቸው።"
        },
        {
            id: "filsata", calendar: "ethiopian", month: 12, day: 16,
            imagePool: "saint-mary", image: "saint-mary.webp",
            title: "ፍልሰታ ለማርያም", category: "የቅድስት ማርያም መታሰቢያ",
            description: "ፍልሰታ ለማርያም ከጾም፣ ከጸሎት እና ከመንፈሳዊ ንቃት ጋር የተያያዘ የእመቤታችን መታሰቢያ ነው።",
            verse: "ከዛሬ ጀምሮ ትውልድ ሁሉ ምስጉን ይሉኛል።",
            reference: "ሉቃስ 1፥48",
            reflection: "ይህ በዓል በቅድስት ማርያም ሕይወትና በእምነት ትውፊት ላይ ለማሰላሰል ይጋብዛል።"
        },
        {
            id: "beata-mariam", calendar: "ethiopian", month: 4, day: 3,
            title: "በዓታ ለማርያም", category: "የቅድስት ማርያም ቤተ መቅደስ መግቢያ መታሰቢያ",
            description: "በዓታ ለማርያም ቅድስት ማርያም ወደ ቤተ መቅደስ መግባቷን የሚያስታውስ በዓል ነው። የንጽሕናን፣ የመታዘዝን እና የእግዚአብሔርን እቅድ መቀበልን ያስተምራል።",
            verse: "ልጄ ሆይ፥ የአባትህን ትእዛዝ ጠብቅ፥ የእናትህንም ሕግ አትተው።",
            reference: "ምሳሌ 6፥20",
            reflection: "ይህ ጥቅስ በእምነት ትውፊት የቤተሰብን ምክር እና ትምህርት ለማስታወስ ይጠቅማል።"
        },
        {
            id: "holy-trinity-tirr", calendar: "ethiopian", month: 5, day: 7,
            title: "ጥር ሥላሴ", category: "የቅድስት ሥላሴ ዓመታዊ መታሰቢያ",
            description: "ጥር 7 በቅድስት ሥላሴ ስም የሚከበር መታሰቢያ ሲሆን፣ የእምነትን ምሥጢርና የአብ፣ የወልድ እና የመንፈስ ቅዱስን አንድነት ያስታውሳል።",
            verse: "በአብ፥ በወልድ፥ በመንፈስ ቅዱስም ስም አጥምቁአቸው።",
            reference: "ማቴዎስ 28፥19",
            reflection: "ይህ ጥቅስ የክርስቲያናዊ ጥምቀትን በሥላሴ ስም እንዲፈጸም ያዛል።"
        },
        {
            id: "mikael-tirr", calendar: "ethiopian", month: 5, day: 12,
            image: "saint-michael.webp",
            title: "ጥር ሚካኤል", category: "የቅዱስ ሚካኤል ዓመታዊ መታሰቢያ",
            description: "ቅዱስ ሚካኤል በየወሩ 12ኛው ቀን ይታሰባል፤ አንዳንድ የመታሰቢያ ዝርዝሮች ጥር 12ንም እንደ ዓመታዊ በዓል ይጠቅሳሉ።",
            verse: "በሰማይም ሰልፍ ሆነ፤ ሚካኤልና መላእክቱ ዘንዶውን ተዋጉ።",
            reference: "ራእይ 12፥7",
            reflection: "የሚካኤል ዓመታዊ በዓላት የሚጠቀሱባቸው ቀናት እንደ አካባቢያዊ ሴንክሳር ዝርዝሮች ሊለያዩ ይችላሉ።"
        },
        {
            id: "gebre-menfes-kidus", calendar: "ethiopian", month: 7, day: 5,
            title: "አቡነ ገብረ መንፈስ ቅዱስ", category: "ዓመታዊ የቅዱሱ መታሰቢያ",
            description: "አቡነ ገብረ መንፈስ ቅዱስ በጸሎት፣ በትሕትና እና በመንፈሳዊ ትጋት የሚታወሱ ቅዱስ አባት ናቸው። ሕይወታቸው የጸሎትንና የቅድስናን አስፈላጊነት ያሳስባል።",
            verse: "በፍቅር ተመላለሱ፥ ክርስቶስም ወደደን።",
            reference: "ኤፌሶን 5፥2",
            reflection: "ይህ ጥቅስ በፍቅርና በርኅራኄ ለመኖር ያበረታታል።"
        },
        {
            id: "medhanialem-megabit", calendar: "ethiopian", month: 7, day: 27,
            title: "መድኃኔዓለም", category: "የዓለም መድኃኒት መታሰቢያ",
            description: "መድኃኔዓለም በክርስቶስ የመዳንን ተስፋ የሚያበስር መታሰቢያ ነው። ይህ ቀን ምሕረትን፣ ይቅርታን እና በእግዚአብሔር የሚገኘውን ተስፋ ለማሰላሰል ይጋብዛል።",
            verse: "እርሱ ራሱ የኃጢአታችን ማስተስረያ ነው።",
            reference: "1 ዮሐንስ 2፥2",
            reflection: "ይህ ጥቅስ ክርስቶስን የመዳን ተስፋ እንደሆነ ያሳያል።"
        },
        {
            id: "tekle-haymanot-nehase", calendar: "ethiopian", month: 12, day: 24,
            title: "አቡነ ተክለ ሃይማኖት", category: "ዓመታዊ የቅዱሱ መታሰቢያ",
            description: "አቡነ ተክለ ሃይማኖት በጸሎታቸው፣ በትሕትናቸው እና በመንፈሳዊ ሕይወታቸው የሚታወሱ ቅዱስ አባት ናቸው። መታሰቢያቸው ታማኝነትንና ጽናትን ያስታውሳል።",
            verse: "በፊታችን የተደረገውን ሩጫ በትዕግሥት እንሩጥ።",
            reference: "ዕብራውያን 12፥1",
            reflection: "ይህ ጥቅስ በእምነት ጉዞ ውስጥ ጽናትን እና ትዕግሥትን ያስታውሳል።"
        },
        {
            id: "ethiopian-martyrs-day", calendar: "gregorian", month: 2, day: 20,
            title: "የኢትዮጵያ ሰማዕታት ቀን", category: "ሀገራዊ የመታሰቢያ ቀን",
            description: "የኢትዮጵያ ሰማዕታትን ለማስታወስ በየዓመቱ የሚከበር ብሔራዊ የመታሰቢያ ቀን።",
            verse: "ለእውነት ታገሉ፥ ጽኑም።",
            reference: "ኤፌሶን 6፥13",
            reflection: "ይህ ቀን በታሪክ ውስጥ ለሕዝብ እና ለነፃነት የተሠዉትን ያስታውሳል።"
        },
        {
            id: "derg-downfall", calendar: "gregorian", month: 5, day: 28,
            title: "የደርግ ውድቀት መታሰቢያ", category: "የታሪክ መታሰቢያ · የመዝጊያ በዓል አይደለም",
            description: "ግንቦት 28 የደርግ መንግሥት መውደቅን በታሪክ ለማስታወስ በብዙ የበዓላት ዝርዝሮች ይጠቀሳል፤ በ2024 የሕዝብ በዓላት አዋጅ እንደ መዝጊያ በዓል አልተዘረዘረም።",
            verse: "ፍትሕን እንድትፈጽሙ እና ምሕረትን እንድትወዱ ተነግሮሃል።",
            reference: "ሚክያስ 6፥8",
            reflection: "ይህ የታሪክ መታሰቢያ ያለፈውን ለማስታወስ እና ሰላምን ለመጠበቅ ይጋብዛል።"
        },
        {
            id: "ethiopian-national-unity", calendar: "gregorian", month: 12, day: 9,
            title: "የብሔር ብሔረሰቦች ቀን", category: "ሀገራዊ የመታሰቢያ ቀን",
            description: "ታኅሣሥ 9 የኢትዮጵያ ብሔር ብሔረሰቦች እኩልነትን፣ ብዝሃነትን እና አንድነትን ለማስታወስ የሚከበር ቀን ነው።",
            verse: "በሰላም የሚያደርገውን እንከተል።",
            reference: "ሮሜ 14፥19",
            reflection: "ቀኑ የተለያዩ ማንነቶችን በእኩልነትና በመከባበር ማስተናገድን ያስታውሳል።"
        },
        {
            id: "eid-al-fitr", calendar: "islamic", month: 10, day: 1,
            title: "ዒድ አል-ፊጥር", category: "የእስልምና በዓል · ግምታዊ ቀን",
            showScripture: false,
            description: "የረመዳን ጾም መጨረሻ በዓል። ታቡላር የእስልምና ቀን መቁጠሪያ የተገመተ ቀን ነው፤ የጨረቃ እይታ የአካባቢውን ቀን ሊያስቀይር ይችላል።",
            verse: "ለሌሎች ርኅራኄን አድርጉ።",
            reference: "መንፈሳዊ ማሰላሰያ",
            reflection: "የታቡላር ሂሳብ ቀን ከኦፊሴላዊ የጨረቃ እይታ ማረጋገጫ አንድ ቀን ሊለይ ይችላል።"
        },
        {
            id: "eid-al-adha", calendar: "islamic", month: 12, day: 10,
            title: "ዒድ አል-አድሓ", category: "የእስልምና በዓል · ግምታዊ ቀን",
            showScripture: false,
            description: "የመስዋዕት በዓል። ይህ በታቡላር የእስልምና ቀን መቁጠሪያ የተገመተ ቀን ሲሆን በአካባቢያዊ የጨረቃ እይታ ሊለይ ይችላል።",
            verse: "ለሰዎች መልካም ነገር አድርጉ።",
            reference: "መንፈሳዊ ማሰላሰያ",
            reflection: "የግምት ቀን ነው፤ ከተከበረበት አካባቢ ኦፊሴላዊ ማረጋገጫ ጋር ያረጋግጡ።"
        },
        {
            id: "mawlid", calendar: "islamic", month: 3, day: 12,
            title: "መውሊድ", category: "የእስልምና መታሰቢያ · ግምታዊ ቀን",
            showScripture: false,
            description: "የነቢዩ ሙሐመድ ልደት መታሰቢያ። ቀኑ በታቡላር የእስልምና ቀን መቁጠሪያ የተገመተ ነው።",
            verse: "ሰላምን እና መልካም ሥራን ፈልጉ።",
            reference: "መንፈሳዊ ማሰላሰያ",
            reflection: "የእስልምና መታሰቢያው ቀን በጨረቃ እይታ ሊለይ ይችላል።"
        },
        {
            id: "debre-tabor", calendar: "ethiopian", month: 12, day: 13,
            title: "ደብረ ታቦር", category: "የጌታችን መለወጥ በዓል",
            description: "ነሐሴ 13 የኢየሱስ ክርስቶስ በደብረ ታቦር ተራራ ላይ መለወጡን የሚያስታውስ ታላቅ በዓል ነው።",
            verse: "ፊቱ እንደ ፀሐይ አበራ፥ ልብሱም እንደ ብርሃን ነጭ ሆነ።",
            reference: "ማቴዎስ 17፥2",
            reflection: "ደብረ ታቦር የክርስቶስን መለኮታዊ ክብር የምናስብበት በዓል ነው።"
        }
    ]

    readonly property var fallbackCommemoration: ({
        title: "የዕለቱ መንፈሳዊ ማሰላሰያ",
        category: "የቀኑ ማሰላሰያ",
        description: "ይህ ቀን በሰላም፣ በጸሎት እና በመልካም ሥራ ላይ እንድናተኩር ይጋብዛል። በየዕለቱ የሚታወሱ መንፈሳዊ እሴቶች በእምነትና በተስፋ እንድንመላለስ ያበረታታሉ።",
        verse: "ይህ እግዚአብሔር ያደረገው ቀን ነው፤ በእርሱ ደስ ይበለን ሐሴትም እናድርግ።",
        reference: "መዝሙር 118፥24",
        reflection: "እያንዳንዱን ቀን በምስጋና እና በተስፋ ለመቀበል የሚረዳ ቃል።"
    })

    readonly property var ethiopianMonths: [
        "መስከረም", "ጥቅምት", "ሕዳር", "ታህሳስ",
        "ጥር", "የካቲት", "መጋቢት", "ሚያዝያ",
        "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜ"
    ]

    function imageForDay(day) {
        if (day === 12)
            return "saint-michael.webp"
        if (day === 16)
            return "kidane-mehret.webp"
        if (day === 21)
            return "saint-mary.webp"
        return ""
    }

    function imagePoolForDay(day) {
        if (day === 16)
            return "kidane-mehret"
        if (day === 21)
            return "saint-mary"
        return ""
    }

    function forDay(day) {
        const commemoration = root.monthlyCommemorations[String(day)] || root.fallbackCommemoration
        return Object.assign({}, commemoration, {
            image: commemoration.image || root.imageForDay(day),
            imagePool: commemoration.imagePool || root.imagePoolForDay(day)
        })
    }

    function forDate(month, day) {
        const annual = root.annualFeasts.find(event =>
            event.calendar === "ethiopian" && event.month === month && event.day === day)
        if (annual)
            return Object.assign({}, annual, {
                image: annual.image || root.imageForDay(day),
                imagePool: annual.imagePool || root.imagePoolForDay(day)
            })
        return root.forDay(day)
    }

    function gregorianToJdn(date) {
        const month = date.getMonth() + 1
        const day = date.getDate()
        let year = date.getFullYear()
        const a = Math.floor((14 - month) / 12)
        year += 4800 - a
        const m = month + 12 * a - 3
        return day + Math.floor((153 * m + 2) / 5) + 365 * year
            + Math.floor(year / 4) - Math.floor(year / 100)
            + Math.floor(year / 400) - 32045
    }

    function ethiopianYearStartJdn(year) {
        return 1723856 + 365 * year + Math.floor(year / 4)
    }

    function toEthiopianDate(date) {
        const jdn = root.gregorianToJdn(date)
        let year = date.getFullYear() - 7
        while (root.ethiopianYearStartJdn(year) > jdn)
            year--
        while (root.ethiopianYearStartJdn(year + 1) <= jdn)
            year++
        const dayOfYear = jdn - root.ethiopianYearStartJdn(year)
        return {
            year: year,
            month: Math.max(1, Math.min(13, Math.floor(dayOfYear / 30) + 1)),
            day: dayOfYear % 30 + 1
        }
    }

    function julianDayToGregorian(jdn) {
        const a = jdn + 32044
        const b = Math.floor((4 * a + 3) / 146097)
        const c = a - Math.floor(146097 * b / 4)
        const d = Math.floor((4 * c + 3) / 1461)
        const e = c - Math.floor(1461 * d / 4)
        const m = Math.floor((5 * e + 2) / 153)
        const gregorianDay = e - Math.floor((153 * m + 2) / 5) + 1
        const gregorianMonth = m + 3 - 12 * Math.floor(m / 10)
        const gregorianYear = 100 * b + d - 4800 + Math.floor(m / 10)
        return new Date(gregorianYear, gregorianMonth - 1, gregorianDay, 12, 0, 0, 0)
    }

    function ethiopianDateToGregorian(year, month, day) {
        const jdn = root.ethiopianYearStartJdn(year) + 30 * (month - 1) + day - 1
        return root.julianDayToGregorian(jdn)
    }

    function islamicDateToGregorian(year, month, day) {
        // Arithmetic/tabular Hijri conversion is an estimate only. Official
        // local observance may move by one day depending on crescent sightings.
        const jdn = day + Math.ceil(29.5 * (month - 1))
            + (year - 1) * 354 + Math.floor((3 + 11 * year) / 30) + 1948439
        return root.julianDayToGregorian(jdn)
    }

    function orthodoxEaster(year) {
        // Orthodox Easter computed in the Julian calendar, then shifted to
        // Gregorian civil dates (the two calendars differ by 13 days in 1900–2099).
        const a = year % 4
        const b = year % 7
        const c = year % 19
        const d = (19 * c + 15) % 30
        const e = (2 * a + 4 * b - d + 34) % 7
        const julianMonth = Math.floor((d + e + 114) / 31)
        const julianDay = ((d + e + 114) % 31) + 1
        return new Date(year, julianMonth - 1, julianDay + 13, 12, 0, 0, 0)
    }

    function decorateEvent(event, date, todayMidnight) {
        const civilDate = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0)
        const ethiopian = root.toEthiopianDate(date)
        return Object.assign({}, event, {
            date: date,
            ethiopianYear: ethiopian.year,
            ethiopianMonth: ethiopian.month,
            ethiopianDay: ethiopian.day,
            daysUntil: Math.max(0, Math.round((civilDate.getTime() - todayMidnight.getTime()) / 86400000))
        })
    }

    function upcomingEvents(now, limit) {
        const count = Math.max(1, Math.min(8, Number(limit) || 5))
        const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0)
        const todayEthiopian = root.toEthiopianDate(now)
        const candidates = []

        // Ethiopian-calendar feasts recur by Ethiopian month/day.
        for (let year = todayEthiopian.year; year <= todayEthiopian.year + 2; year++) {
            for (const event of root.annualFeasts) {
                if (event.calendar !== "ethiopian")
                    continue
                const date = root.ethiopianDateToGregorian(year, event.month, event.day)
                candidates.push(root.decorateEvent(event, date, todayMidnight))
            }
        }

        // Fixed Gregorian national and memorial days.
        for (let year = now.getFullYear(); year <= now.getFullYear() + 2; year++) {
            for (const event of root.annualFeasts) {
                if (event.calendar !== "gregorian")
                    continue
                const date = new Date(year, event.month - 1, event.day, 12, 0, 0, 0)
                candidates.push(root.decorateEvent(event, date, todayMidnight))
            }

            const easter = root.orthodoxEaster(year)
            const calculatedFeasts = [
                {
                    id: "debre-zeit", offset: -28,
                    title: "ደብረ ዘይት", category: "የዐቢይ ጾም የሚንቀሳቀስ መታሰቢያ",
                    description: "የደብረ ዘይት መታሰቢያ ከፋሲካ በፊት ባለው የዐቢይ ጾም የተወሰነ እሁድ ይከበራል።",
                    verse: "በበሩ ግቡ፤ በሩ ሰፊ ነውና፥ መንገዱም ሰፊ ነውና።",
                    reference: "ማቴዎስ 7፥13",
                    reflection: "ደብረ ዘይት በዐቢይ ጾም ውስጥ የሚከበር ተንቀሳቃሽ መታሰቢያ ነው።"
                },
                {
                    id: "palm-sunday", offset: -7,
                    title: "ሆሣዕና", category: "የመዳን ሳምንት በዓል",
                    description: "ኢየሱስ ክርስቶስ ወደ ኢየሩሳሌም በድል መግባቱን የሚያስታውስ ቀን።",
                    verse: "ሆሣዕና፤ በጌታ ስም የሚመጣ የተባረከ ነው።",
                    reference: "ዮሐንስ 12፥13",
                    reflection: "ሆሣዕና የቅዱሱን ሳምንት መጀመሪያ ያመለክታል።"
                },
                {
                    id: "siklet", offset: -2,
                    title: "ስቅለት", category: "የታላቁ ሳምንት በዓል",
                    description: "የኢየሱስ ክርስቶስን ስቅለት የሚያስታውስ ቀን።",
                    verse: "ተፈጸመ።",
                    reference: "ዮሐንስ 19፥30",
                    reflection: "ስቅለት የክርስቶስን መስዋዕትነት ለማሰብ የሚለይ ቀን ነው።"
                },
                {
                    id: "fasika", offset: 0,
                    title: "ፋሲካ", category: "የትንሣኤ በዓል · ሀገራዊ በዓል",
                    description: "የኢየሱስ ክርስቶስን ትንሣኤ የሚያከብር በዓል።",
                    verse: "ከሞት ተነሥቷል፤ እንዳለ አይደለምን?",
                    reference: "ማቴዎስ 28፥6",
                    reflection: "ፋሲካ የትንሣኤን፣ የድልን እና የአዲስ ሕይወትን ተስፋ ያከብራል።"
                },
                {
                    id: "ascension", offset: 39,
                    title: "ዕርገት", category: "የጌታችን ዕርገት",
                    description: "ከትንሣኤ በኋላ ክርስቶስ ወደ ሰማይ መውጣቱን የሚያስታውስ በዓል።",
                    verse: "እነርሱም እያዩት ወደ ሰማይ አረገ።",
                    reference: "ሐዋርያት ሥራ 1፥9",
                    reflection: "ዕርገት በትንሣኤ በኋላ በአርባኛው ቀን ይታሰባል።"
                },
                {
                    id: "pentecost", offset: 49,
                    title: "ጰራቅሊጦስ", category: "የመንፈስ ቅዱስ መውረድ",
                    description: "መንፈስ ቅዱስ በሐዋርያት ላይ መውረዱን የሚያስታውስ በዓል።",
                    verse: "ሁሉም በመንፈስ ቅዱስ ተሞሉ።",
                    reference: "ሐዋርያት ሥራ 2፥4",
                    reflection: "ጰራቅሊጦስ ከትንሣኤ ከሃምሳኛው ቀን ጋር ይያያዛል።"
                }
            ]
            for (const feast of calculatedFeasts) {
                const date = new Date(easter.getFullYear(), easter.getMonth(),
                    easter.getDate() + feast.offset, 12, 0, 0, 0)
                candidates.push(root.decorateEvent(feast, date, todayMidnight))
            }
        }

        // Lunar Islamic holidays use the arithmetic Hijri calendar as a preview.
        // Their final local dates can differ by one day after official moon sighting.
        const currentIslamicYear = Math.floor((now.getFullYear() - 622) * 33 / 32)
        for (let year = currentIslamicYear; year <= currentIslamicYear + 3; year++) {
            for (const event of root.annualFeasts) {
                if (event.calendar !== "islamic")
                    continue
                const date = root.islamicDateToGregorian(year, event.month, event.day)
                candidates.push(root.decorateEvent(event, date, todayMidnight))
            }
        }

        return candidates
            .filter(event => event.date.getTime() >= todayMidnight.getTime())
            .sort((a, b) => a.date.getTime() - b.date.getTime())
            .slice(0, count)
    }
}
