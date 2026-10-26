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
            title: "ሕዳር ሚካኤል", category: "የቅዱስ ሚካኤል ታላቅ ዓመታዊ በዓል",
            description: "ቅዱስ ሚካኤል በየወሩ 12ኛው ቀን ይታሰባል፤ ሕዳር 12 ከሁለቱ ዋና ዋና ዓመታዊ በዓላቱ አንዱ ነው።",
            verse: "በሰማይም ሰልፍ ሆነ፤ ሚካኤልና መላእክቱ ዘንዶውን ተዋጉ።",
            reference: "ራእይ 12፥7",
            reflection: "የቅዱስ ሚካኤል ዓመታዊ መታሰቢያ በሕዳር 12 ይከበራል።"
        },
        {
            id: "lideta-tahsas", calendar: "ethiopian", month: 4, day: 1,
            title: "ልደታ ለማርያም", category: "የቅድስት ማርያም ዓመታዊ በዓል",
            description: "በታኅሣሥ 1 የቅድስት ማርያም ልደት የሚታሰብበት የልደታ መታሰቢያ ነው።",
            verse: "ከዛሬ ጀምሮ ትውልድ ሁሉ ምስጉን ይሉኛል።",
            reference: "ሉቃስ 1፥48",
            reflection: "ይህ ጥቅስ በማርያም የምስጋና መዝሙር ውስጥ ይገኛል።"
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
            title: "የካቲት ኪዳነ ምሕረት", category: "የቅድስት ማርያም ዓመታዊ መታሰቢያ",
            description: "የካቲት 16 ከኪዳነ ምሕረት ዋና መታሰቢያዎች አንዱ ነው።",
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
            title: "ልደታ ለማርያም", category: "የቅድስት ማርያም ዓመታዊ በዓል",
            description: "ግንቦት 1 ልደታ ለማርያም የሚታሰብበት ሌላው ዓመታዊ ቀን ነው።",
            verse: "ከዛሬ ጀምሮ ትውልድ ሁሉ ምስጉን ይሉኛል።",
            reference: "ሉቃስ 1፥48",
            reflection: "ይህ ጥቅስ በማርያም የምስጋና መዝሙር ውስጥ ይገኛል።"
        },
        {
            id: "mikael-sene", calendar: "ethiopian", month: 10, day: 12,
            title: "ሰኔ ሚካኤል", category: "የቅዱስ ሚካኤል ታላቅ ዓመታዊ በዓል",
            description: "ሰኔ 12 ለቅዱስ ሚካኤል ከተለዩት ሁለት ዋና ዋና ዓመታዊ በዓላት አንዱ ነው።",
            verse: "በሰማይም ሰልፍ ሆነ፤ ሚካኤልና መላእክቱ ዘንዶውን ተዋጉ።",
            reference: "ራእይ 12፥7",
            reflection: "ቅዱስ ሚካኤል በየወሩ 12ኛው ቀን ይታሰባል፤ ሕዳር 12 እና ሰኔ 12 ዋና ዓመታዊ በዓላቱ ናቸው።"
        },
        {
            id: "filsata", calendar: "ethiopian", month: 12, day: 16,
            title: "ፍልሰታ ለማርያም", category: "የቅድስት ማርያም መታሰቢያ",
            description: "ከነሐሴ 1 እስከ 16 የሚከበረው የፍልሰታ ጾም በነሐሴ 16 ይደርሳል።",
            verse: "ከዛሬ ጀምሮ ትውልድ ሁሉ ምስጉን ይሉኛል።",
            reference: "ሉቃስ 1፥48",
            reflection: "ይህ በዓል በቅድስት ማርያም ሕይወትና በእምነት ትውፊት ላይ ለማሰላሰል ይጋብዛል።"
        }
    ]

    readonly property var fallbackCommemoration: ({
        title: "የዕለቱ መንፈሳዊ ማሰላሰያ",
        category: "የቀኑ ማሰላሰያ",
        description: "ይህ ቀን በሰላም፣ በጸሎት እና በመልካም ሥራ እንዲኖር ያስታውሰናል። ተጨማሪ የቀን መታሰቢያዎች በቀጣይ ዝማኔዎች ይጨመራሉ።",
        verse: "ይህ እግዚአብሔር ያደረገው ቀን ነው፤ በእርሱ ደስ ይበለን ሐሴትም እናድርግ።",
        reference: "መዝሙር 118፥24",
        reflection: "እያንዳንዱን ቀን በምስጋና እና በተስፋ ለመቀበል የሚረዳ ቃል።"
    })

    readonly property var ethiopianMonths: [
        "መስከረም", "ጥቅምት", "ሕዳር", "ታህሳስ",
        "ጥር", "የካቲት", "መጋቢት", "ሚያዝያ",
        "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜ"
    ]

    function forDate(month, day) {
        const annual = root.annualFeasts.find(event =>
            event.calendar === "ethiopian" && event.month === month && event.day === day)
        if (annual)
            return annual
        return root.monthlyCommemorations[String(day)] || root.fallbackCommemoration
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

    function ethiopianDateToGregorian(year, month, day) {
        const jdn = root.ethiopianYearStartJdn(year) + 30 * (month - 1) + day - 1
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

        // Civil public holidays recur on fixed Gregorian month/day.
        for (let year = now.getFullYear(); year <= now.getFullYear() + 2; year++) {
            for (const event of root.annualFeasts) {
                if (event.calendar !== "gregorian")
                    continue
                const date = new Date(year, event.month - 1, event.day, 12, 0, 0, 0)
                candidates.push(root.decorateEvent(event, date, todayMidnight))
            }

            const easter = root.orthodoxEaster(year)
            const siklet = new Date(easter.getFullYear(), easter.getMonth(), easter.getDate() - 2, 12, 0, 0, 0)
            candidates.push(root.decorateEvent({
                id: "siklet",
                title: "ስቅለት",
                category: "የታላቁ ሳምንት በዓል",
                description: "የኢየሱስ ክርስቶስን ስቅለት የሚያስታውስ ቀን።",
                verse: "ተፈጸመ።",
                reference: "ዮሐንስ 19፥30",
                reflection: "ስቅለት የክርስቶስን መስዋዕትነት ለማሰብ የሚለይ ቀን ነው።"
            }, siklet, todayMidnight))
            candidates.push(root.decorateEvent({
                id: "fasika",
                title: "ፋሲካ",
                category: "የትንሣኤ በዓል · ሀገራዊ በዓል",
                description: "የኢየሱስ ክርስቶስን ትንሣኤ የሚያከብር በዓል።",
                verse: "ከሞት ተነሥቷል፤ እንዳለ አይደለምን?",
                reference: "ማቴዎስ 28፥6",
                reflection: "ፋሲካ የትንሣኤን፣ የድልን እና የአዲስ ሕይወትን ተስፋ ያከብራል።"
            }, easter, todayMidnight))
        }

        return candidates
            .filter(event => event.date.getTime() >= todayMidnight.getTime())
            .sort((a, b) => a.date.getTime() - b.date.getTime())
            .slice(0, count)
    }
}
