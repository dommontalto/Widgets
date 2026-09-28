//
//  GraphWorkbenchDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import Foundation

enum GraphWorkbenchDemo {
    static let data = makeData()

    private struct Entity {
        let id: String
        let title: String
        let type: GraphEntityType
        let frequency: Int
        let community: String
        let description: String
    }

    private struct Community {
        let id: String
        let parentID: String?
        let title: String
        let summary: String
    }

    private static func makeData() -> GraphWorkbenchData {
        let relationships = relationshipRows.enumerated().map { index, row in
            GraphRelationship(
                id: "r\(index)",
                source: row.0,
                target: row.1,
                description: row.3,
                weight: row.2
            )
        }

        var degrees: [String: Int] = [:]
        for relationship in relationships {
            degrees[relationship.source, default: 0] += 1
            degrees[relationship.target, default: 0] += 1
        }

        // Each domain hands out its shades in turn, so neighbours in the same
        // domain rarely share one.
        var shadeCounts: [GraphEntityType: Int] = [:]
        let entities = entityRows.enumerated().map { index, row in
            let shade = shadeCounts[row.type, default: 0]
            shadeCounts[row.type] = shade + 1
            return GraphEntity(
                id: row.id,
                humanReadableID: index,
                title: row.title,
                type: row.type,
                shade: shade,
                description: row.description,
                frequency: row.frequency,
                degree: degrees[row.id, default: 0]
            )
        }

        // A parent community holds every entity of its children, as GraphRAG's
        // hierarchical Leiden output does.
        let communities = communityRows.map { row in
            let leafIDs = communityRows
                .filter { $0.id == row.id || $0.parentID == row.id }
                .map(\.id)
            return GraphCommunity(
                id: row.id,
                level: row.parentID == nil ? 0 : 1,
                parentID: row.parentID,
                title: row.title,
                summary: row.summary,
                entityIDs: entityRows.filter { leafIDs.contains($0.community) }.map(\.id)
            )
        }

        return GraphWorkbenchData(
            name: "Health Graph",
            entities: entities,
            relationships: relationships,
            communities: communities
        )
    }

    private static let communityRows: [Community] = [
        Community(
            id: "0",
            parentID: nil,
            title: "Sleep & Recovery",
            summary: "How well you sleep, when you sleep, and the stress and caffeine that shift both."
        ),
        Community(
            id: "1",
            parentID: nil,
            title: "Cardio Fitness",
            summary: "Your heart's resting markers and the training that moves them."
        ),
        Community(
            id: "2",
            parentID: nil,
            title: "Metabolic Health",
            summary: "What you eat and drink, and the blood markers and genes that show how your body handles it."
        ),
        Community(
            id: "3",
            parentID: "0",
            title: "Sleep Stages",
            summary: "The architecture of a night: deep, REM and light sleep, and what's measured during it."
        ),
        Community(
            id: "4",
            parentID: "0",
            title: "Stress & Circadian Rhythm",
            summary: "The body clock, the hormones that run it, and the mind and caffeine habits that push it around."
        ),
        Community(
            id: "5",
            parentID: "1",
            title: "Heart Health",
            summary: "Resting heart rate, HRV, blood pressure and the lipids behind long-term heart risk."
        ),
        Community(
            id: "6",
            parentID: "1",
            title: "Training",
            summary: "Zone 2, intervals and strength work, and the load, fatigue and readiness they produce."
        ),
        Community(
            id: "7",
            parentID: "2",
            title: "Nutrition",
            summary: "Macros, hydration and meal timing."
        ),
        Community(
            id: "8",
            parentID: "2",
            title: "Biomarkers",
            summary: "The Vault's clinical markers for glucose, inflammation, hormones and micronutrients."
        ),
    ]

    private static let entityRows: [Entity] = [
        Entity(id: "deepSleep", title: "Deep Sleep", type: .sleep, frequency: 16, community: "3",
               description: "Slow-wave sleep, when the body does most of its physical repair. Front-loaded into the first half of the night."),
        Entity(id: "remSleep", title: "REM Sleep", type: .sleep, frequency: 14, community: "3",
               description: "The dreaming stage, tied to memory and mood. It lengthens through the second half of the night."),
        Entity(id: "lightSleep", title: "Light Sleep", type: .sleep, frequency: 9, community: "3",
               description: "The transitional stage that makes up about half of a typical night."),
        Entity(id: "sleepScore", title: "Sleep Score", type: .sleep, frequency: 18, community: "3",
               description: "Bright's nightly summary of duration, stages and disruptions."),
        Entity(id: "timeAsleep", title: "Time Asleep", type: .sleep, frequency: 12, community: "3",
               description: "Total sleep across the night, not counting time spent awake in bed."),
        Entity(id: "awakeTime", title: "Awake Time", type: .sleep, frequency: 7, community: "3",
               description: "Minutes spent awake after first falling asleep."),
        Entity(id: "respiratoryRate", title: "Respiratory Rate", type: .heart, frequency: 5, community: "3",
               description: "Breaths per minute during sleep. A sustained rise can signal illness or strain."),
        Entity(id: "bloodOxygen", title: "Blood Oxygen", type: .heart, frequency: 5, community: "3",
               description: "Overnight SpO₂. Repeated dips can point to disordered breathing."),
        Entity(id: "growthHormone", title: "Growth Hormone", type: .biomarker, frequency: 4, community: "3",
               description: "Released in pulses during deep sleep, supporting tissue repair."),

        Entity(id: "circadianRhythm", title: "Circadian Rhythm", type: .sleep, frequency: 13, community: "4",
               description: "The body's roughly 24-hour clock, set mainly by light and meal timing."),
        Entity(id: "bedtimeConsistency", title: "Bedtime Consistency", type: .sleep, frequency: 8, community: "4",
               description: "How much your sleep and wake times vary across the week."),
        Entity(id: "melatonin", title: "Melatonin", type: .biomarker, frequency: 6, community: "4",
               description: "The hormone that rises in the evening dark and signals it's time to sleep."),
        Entity(id: "cortisol", title: "Cortisol", type: .biomarker, frequency: 9, community: "4",
               description: "The stress hormone. Peaks shortly after waking and should fall through the day."),
        Entity(id: "caffeine", title: "Caffeine", type: .nutrition, frequency: 10, community: "4",
               description: "Blocks adenosine to hold off sleepiness. Its half-life runs five to six hours."),
        Entity(id: "cyp1a2", title: "CYP1A2 rs762551", type: .genome, frequency: 4, community: "4",
               description: "Caffeine metabolism. Slow metabolisers keep caffeine in their system for longer."),
        Entity(id: "adora2a", title: "ADORA2A rs5751876", type: .genome, frequency: 3, community: "4",
               description: "Caffeine-sleep sensitivity. Some variants make sleep more easily disrupted by caffeine."),
        Entity(id: "stress", title: "Stress", type: .mind, frequency: 12, community: "4",
               description: "Logged stress from Mind check-ins, alongside its physiological signals."),
        Entity(id: "mood", title: "Mood", type: .mind, frequency: 9, community: "4",
               description: "Daily mood from Mind check-ins."),
        Entity(id: "journaling", title: "Journaling", type: .mind, frequency: 5, community: "4",
               description: "Evening journal entries in Bright."),
        Entity(id: "meditation", title: "Meditation", type: .mind, frequency: 6, community: "4",
               description: "Guided breathing and meditation sessions."),

        Entity(id: "restingHeartRate", title: "Resting Heart Rate", type: .heart, frequency: 15, community: "5",
               description: "Beats per minute at rest. It falls as aerobic fitness improves."),
        Entity(id: "hrv", title: "HRV", type: .heart, frequency: 17, community: "5",
               description: "Heart rate variability, a read on the nervous system's balance and recovery."),
        Entity(id: "heartScore", title: "Heart Score", type: .heart, frequency: 11, community: "5",
               description: "Bright's summary of resting heart rate, HRV and cardio fitness."),
        Entity(id: "bloodPressure", title: "Blood Pressure", type: .heart, frequency: 8, community: "5",
               description: "Systolic and diastolic pressure, the biggest modifiable driver of heart risk."),
        Entity(id: "ldl", title: "LDL Cholesterol", type: .biomarker, frequency: 7, community: "5",
               description: "The cholesterol carried by low-density lipoprotein."),
        Entity(id: "apoB", title: "ApoB", type: .biomarker, frequency: 6, community: "5",
               description: "A count of atherogenic particles, often a sharper risk marker than LDL."),
        Entity(id: "recovery", title: "Recovery", type: .exercise, frequency: 12, community: "5",
               description: "How ready the body is to take on load, from HRV, resting heart rate and sleep."),

        Entity(id: "vo2Max", title: "VO2 Max", type: .heart, frequency: 10, community: "6",
               description: "Peak oxygen uptake, one of the strongest single predictors of longevity."),
        Entity(id: "zone2", title: "Zone 2 Cardio", type: .exercise, frequency: 11, community: "6",
               description: "Steady, conversational-pace cardio that builds the aerobic base."),
        Entity(id: "zone5", title: "Zone 5 Intervals", type: .exercise, frequency: 6, community: "6",
               description: "Short, maximal efforts that push VO2 max."),
        Entity(id: "strength", title: "Strength Training", type: .exercise, frequency: 13, community: "6",
               description: "Resistance sessions that build and keep muscle and bone."),
        Entity(id: "trainingLoad", title: "Training Load", type: .exercise, frequency: 9, community: "6",
               description: "The weekly volume and intensity across all sessions."),
        Entity(id: "readiness", title: "Readiness", type: .exercise, frequency: 10, community: "6",
               description: "Whether today suits hard training or an easy day."),
        Entity(id: "fatigue", title: "Fatigue", type: .exercise, frequency: 7, community: "6",
               description: "Accumulated strain that hasn't been recovered from yet."),
        Entity(id: "steps", title: "Steps", type: .exercise, frequency: 8, community: "6",
               description: "Daily steps, the base of everyday activity."),
        Entity(id: "actn3", title: "ACTN3 rs1815739", type: .genome, frequency: 4, community: "6",
               description: "Muscle fibre type. Linked to a lean toward power or endurance."),

        Entity(id: "protein", title: "Protein", type: .nutrition, frequency: 12, community: "7",
               description: "The macro that repairs and builds muscle. Best spread across the day."),
        Entity(id: "carbs", title: "Carbohydrates", type: .nutrition, frequency: 10, community: "7",
               description: "The main fuel for hard training and a driver of blood glucose."),
        Entity(id: "fats", title: "Fats", type: .nutrition, frequency: 8, community: "7",
               description: "Dietary fat, from saturated to polyunsaturated."),
        Entity(id: "fibre", title: "Fibre", type: .nutrition, frequency: 6, community: "7",
               description: "Slows glucose absorption and feeds the gut microbiome."),
        Entity(id: "hydration", title: "Hydration", type: .nutrition, frequency: 7, community: "7",
               description: "Daily fluid intake logged in Bright."),
        Entity(id: "omega3", title: "Omega-3", type: .nutrition, frequency: 5, community: "7",
               description: "EPA and DHA from oily fish, with anti-inflammatory effects."),
        Entity(id: "alcohol", title: "Alcohol", type: .nutrition, frequency: 8, community: "7",
               description: "Sedates, but fragments sleep and suppresses REM and HRV."),
        Entity(id: "lateMeals", title: "Late Meals", type: .nutrition, frequency: 5, community: "7",
               description: "Eating within three hours of bed, which raises overnight heart rate."),
        Entity(id: "mcm6", title: "MCM6 rs4988235", type: .genome, frequency: 3, community: "7",
               description: "Lactose tolerance. Decides whether lactase persists into adulthood."),

        Entity(id: "hba1c", title: "HbA1c", type: .biomarker, frequency: 9, community: "8",
               description: "Average blood glucose over roughly three months."),
        Entity(id: "fastingGlucose", title: "Fasting Glucose", type: .biomarker, frequency: 8, community: "8",
               description: "Blood glucose after an overnight fast."),
        Entity(id: "vitaminD", title: "Vitamin D", type: .biomarker, frequency: 7, community: "8",
               description: "A fat-soluble vitamin involved in bone, immune and muscle health."),
        Entity(id: "ferritin", title: "Ferritin", type: .biomarker, frequency: 6, community: "8",
               description: "The body's iron stores. Low levels sap endurance."),
        Entity(id: "hsCRP", title: "hs-CRP", type: .biomarker, frequency: 8, community: "8",
               description: "A sensitive marker of low-grade systemic inflammation."),
        Entity(id: "tsh", title: "TSH", type: .biomarker, frequency: 5, community: "8",
               description: "Thyroid-stimulating hormone, the first check of thyroid health."),
        Entity(id: "testosterone", title: "Testosterone", type: .biomarker, frequency: 6, community: "8",
               description: "A hormone that drives muscle, energy and libido, and is sensitive to sleep."),
        Entity(id: "gc", title: "GC rs2282679", type: .genome, frequency: 3, community: "8",
               description: "Fat-soluble vitamins. Variants are linked to lower circulating vitamin D."),
        Entity(id: "il6", title: "IL6 rs1800795", type: .genome, frequency: 3, community: "8",
               description: "Inflammation risk. Influences how strongly IL-6 responds to stress."),
        Entity(id: "weight", title: "Body Weight", type: .exercise, frequency: 9, community: "8",
               description: "Weight trend from logged weigh-ins."),
    ]

    // Source, target, weight, description.
    private static let relationshipRows: [(String, String, Int, String)] = [
        ("deepSleep", "sleepScore", 9, "Deep sleep is weighted heavily in the Sleep Score."),
        ("remSleep", "sleepScore", 8, "REM sleep contributes to the Sleep Score."),
        ("lightSleep", "timeAsleep", 6, "Light sleep makes up most of time asleep."),
        ("timeAsleep", "sleepScore", 9, "Duration is the largest single input to the Sleep Score."),
        ("awakeTime", "sleepScore", 7, "Time awake after sleep onset lowers the Sleep Score."),
        ("deepSleep", "growthHormone", 8, "Most growth hormone is released during deep sleep."),
        ("deepSleep", "remSleep", 5, "Deep and REM sleep trade places across the night's cycles."),
        ("respiratoryRate", "sleepScore", 4, "Respiratory rate is tracked alongside each night's score."),
        ("bloodOxygen", "awakeTime", 5, "Oxygen dips often coincide with brief awakenings."),
        ("respiratoryRate", "bloodOxygen", 5, "Both are measured through the night to flag disordered breathing."),
        ("deepSleep", "recovery", 8, "Deep sleep drives next-day recovery."),
        ("growthHormone", "strength", 5, "Growth hormone supports adaptation to strength training."),
        ("timeAsleep", "testosterone", 6, "Short sleep lowers testosterone within a week."),
        ("remSleep", "mood", 6, "REM sleep helps regulate emotion and next-day mood."),

        ("circadianRhythm", "melatonin", 9, "The circadian clock times the evening melatonin rise."),
        ("circadianRhythm", "cortisol", 8, "The circadian clock times the morning cortisol peak."),
        ("bedtimeConsistency", "circadianRhythm", 8, "Regular sleep times keep the circadian rhythm anchored."),
        ("bedtimeConsistency", "sleepScore", 6, "Consistent bedtimes lift the Sleep Score."),
        ("melatonin", "timeAsleep", 6, "Melatonin timing sets how quickly you fall asleep."),
        ("caffeine", "deepSleep", 8, "Afternoon caffeine reduces deep sleep."),
        ("caffeine", "cyp1a2", 7, "CYP1A2 sets how fast caffeine is cleared."),
        ("caffeine", "adora2a", 7, "ADORA2A variants change how strongly caffeine disrupts sleep."),
        ("adora2a", "deepSleep", 5, "Sensitive variants lose more deep sleep to caffeine."),
        ("stress", "cortisol", 8, "Stress raises cortisol."),
        ("stress", "hrv", 8, "Stress suppresses HRV."),
        ("stress", "awakeTime", 6, "High-stress days bring more awakenings."),
        ("stress", "mood", 7, "Stress and mood move together in check-ins."),
        ("journaling", "stress", 5, "Evening journaling is associated with lower stress."),
        ("meditation", "stress", 6, "Meditation sessions lower logged stress."),
        ("meditation", "hrv", 5, "Slow breathing raises HRV during and after a session."),
        ("journaling", "mood", 4, "Journaling days tend to log a better mood."),
        ("cortisol", "sleepScore", 5, "High evening cortisol delays sleep onset."),
        ("lateMeals", "circadianRhythm", 5, "Late meals shift the body clock."),

        ("restingHeartRate", "heartScore", 9, "Resting heart rate feeds the Heart Score."),
        ("hrv", "heartScore", 9, "HRV feeds the Heart Score."),
        ("hrv", "recovery", 9, "HRV is the main input to Recovery."),
        ("restingHeartRate", "recovery", 7, "An elevated resting heart rate lowers Recovery."),
        ("bloodPressure", "heartScore", 6, "Blood pressure is part of the heart picture."),
        ("ldl", "apoB", 8, "Most ApoB particles carry LDL cholesterol."),
        ("apoB", "heartScore", 5, "ApoB adds long-term risk context to heart markers."),
        ("hrv", "deepSleep", 7, "HRV is highest during deep sleep."),
        ("restingHeartRate", "lateMeals", 5, "Late meals raise overnight resting heart rate."),
        ("alcohol", "hrv", 8, "Alcohol suppresses overnight HRV."),
        ("alcohol", "restingHeartRate", 7, "Alcohol raises overnight resting heart rate."),
        ("recovery", "readiness", 9, "Recovery sets today's Readiness."),
        ("bloodPressure", "weight", 5, "Weight loss tends to lower blood pressure."),
        ("fats", "ldl", 6, "Saturated fat raises LDL cholesterol."),
        ("omega3", "hsCRP", 5, "Omega-3 intake lowers inflammation markers."),

        ("zone2", "vo2Max", 8, "Zone 2 builds the aerobic base VO2 max sits on."),
        ("zone5", "vo2Max", 9, "Intervals are the most direct way to raise VO2 max."),
        ("vo2Max", "heartScore", 7, "Cardio fitness is part of the Heart Score."),
        ("zone2", "restingHeartRate", 7, "Aerobic training lowers resting heart rate."),
        ("strength", "trainingLoad", 7, "Strength sessions add to weekly load."),
        ("zone2", "trainingLoad", 6, "Cardio sessions add to weekly load."),
        ("zone5", "trainingLoad", 7, "Intervals add load quickly."),
        ("trainingLoad", "fatigue", 9, "Load that outpaces recovery builds fatigue."),
        ("fatigue", "readiness", 8, "Fatigue lowers Readiness."),
        ("readiness", "zone5", 5, "High readiness is the day to schedule intervals."),
        ("actn3", "strength", 5, "ACTN3 variants influence power and strength response."),
        ("actn3", "zone2", 3, "Some ACTN3 variants lean toward endurance."),
        ("steps", "trainingLoad", 4, "Steps add everyday load."),
        ("steps", "weight", 5, "Daily steps support weight management."),
        ("strength", "protein", 8, "Protein intake supports muscle repair after strength work."),
        ("zone5", "carbs", 6, "Hard intervals run on carbohydrate."),
        ("ferritin", "vo2Max", 5, "Low iron stores cap endurance performance."),
        ("fatigue", "sleepScore", 5, "Heavy training blocks can fragment sleep."),

        ("protein", "weight", 6, "Higher protein helps keep muscle while losing weight."),
        ("carbs", "fastingGlucose", 6, "Refined carbohydrate raises glucose."),
        ("carbs", "hba1c", 5, "Long-run carbohydrate quality shows up in HbA1c."),
        ("fibre", "fastingGlucose", 6, "Fibre blunts glucose spikes."),
        ("fibre", "ldl", 5, "Soluble fibre lowers LDL cholesterol."),
        ("fats", "omega3", 5, "Omega-3s are a polyunsaturated fat."),
        ("hydration", "restingHeartRate", 4, "Dehydration nudges resting heart rate up."),
        ("alcohol", "remSleep", 8, "Alcohol suppresses REM sleep."),
        ("alcohol", "deepSleep", 5, "Alcohol fragments the second half of the night."),
        ("lateMeals", "deepSleep", 5, "Late meals can reduce deep sleep."),
        ("mcm6", "fats", 3, "Lactose tolerance shapes dairy intake."),
        ("mcm6", "protein", 3, "Dairy is a common protein source for tolerant variants."),

        ("hba1c", "fastingGlucose", 8, "HbA1c and fasting glucose both read glucose control."),
        ("weight", "hba1c", 6, "Weight change moves HbA1c."),
        ("vitaminD", "gc", 7, "GC variants are linked to lower vitamin D."),
        ("vitaminD", "testosterone", 4, "Low vitamin D is associated with lower testosterone."),
        ("vitaminD", "mood", 4, "Low vitamin D is associated with low mood in winter."),
        ("hsCRP", "il6", 7, "IL6 variants influence the inflammatory response CRP measures."),
        ("hsCRP", "recovery", 5, "Raised inflammation slows recovery."),
        ("hsCRP", "apoB", 4, "Inflammation and ApoB together sharpen heart risk."),
        ("tsh", "restingHeartRate", 5, "Thyroid function shifts resting heart rate."),
        ("tsh", "weight", 5, "An underactive thyroid can drive weight gain."),
        ("testosterone", "strength", 6, "Testosterone supports strength adaptation."),
        ("ferritin", "fatigue", 5, "Low ferritin shows up as fatigue."),
        ("cortisol", "fastingGlucose", 4, "Cortisol raises morning glucose."),
    ]
}
