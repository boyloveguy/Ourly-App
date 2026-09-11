OURLY - PREFERENCE & SELECTION OPTIONS

Partner preference catalogue and all selectable MVP options

Version: 11 Sep 2026

Purpose: centralize all selectable values so Design, FE, BE and AI use the same labels and validation rules.

Current core validation from the source feature list is preserved: Partner Profile requires Relationship + at least 2 preferences + 1 occasion + 1 budget. The expanded categories below provide more ways to learn the partner’s tastes without forcing the user to complete every category.

A. Partner Profile - Basic Fields

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Relationship | Single select | Required | • Boyfriend<br>• Girlfriend | Relationship to the partner. |
| Occasion | Single select | Required in current MVP planning flow | • Anniversary<br>• Birthday<br>• Date Night<br>• First Date<br>• Celebration<br>• Apology<br>• Cheer Up<br>• Just Because | Used as context for AI advice/recommendation. |
| Budget | Single select | Required | • 200K VND<br>• 300K VND<br>• 500K VND<br>• 700K VND<br>• 1M VND<br>• 1.5M VND<br>• 2M+ VND | Budget should be used by Recommendation filtering. |

B. Partner Preferences - Taste & Lifestyle

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Food | Multi-select | Optional category | • Vietnamese<br>• Japanese<br>• Korean<br>• Italian<br>• BBQ<br>• Seafood<br>• Vegetarian<br>• Street Food<br>• Dessert | Counts toward preference minimum when selected. |
| Drink | Multi-select | Optional category | • Coffee<br>• Matcha<br>• Tea<br>• Milk Tea<br>• Juice<br>• Smoothie<br>• Cocktail | Use for venue and gift context. |
| Vibe | Multi-select | Optional category | • Romantic<br>• Cozy<br>• Quiet<br>• Chill<br>• Luxury<br>• Trendy<br>• Cute<br>• Vintage<br>• Nature<br>• Seaside<br>• Rooftop | Useful for recommendation tags and AI reasoning. |
| Activities | Multi-select | Optional category | • Cafe hopping<br>• Dinner<br>• Movie<br>• Beach walk<br>• Shopping<br>• Workshop<br>• Photography<br>• Picnic<br>• Spa<br>• Outdoor<br>• Staycation<br>• Live music | Can feed experience planning. |
| Interests | Multi-select | Optional category | • Photography<br>• Art<br>• Music<br>• Fashion<br>• Travel<br>• Books<br>• Movies<br>• Gaming<br>• Food<br>• Nature | Useful for gifts, activities and conversation context. |
| Date Style | Multi-select | Optional category | • Relaxing<br>• Romantic<br>• Fun<br>• Adventurous<br>• Creative<br>• Surprise<br>• Simple<br>• Premium | Describes preferred experience style. |
| Favorite Place Type | Multi-select | Optional category | • Beach<br>• Cafe<br>• Restaurant<br>• Rooftop<br>• Park<br>• Mall<br>• Cinema<br>• Hotel<br>• Outdoor | Different from a specific Favorite Place Memory. |
| Gift Preference | Multi-select | Optional category | • Flowers<br>• Jewelry<br>• Handmade gifts<br>• Experiences<br>• Food<br>• Beauty<br>• Fashion<br>• Personalized gifts | Used by gift/advice scenarios. |
| Love Language | Multi-select | Optional category | • Quality Time<br>• Words of Affirmation<br>• Gifts<br>• Acts of Service<br>• Physical Touch | Use as relationship-advice context; do not treat as a clinical assessment. |
| Must-have | Multi-select | Optional category | • Good food<br>• Nice view<br>• Photo-friendly<br>• Quiet space<br>• Air-conditioned<br>• Near beach<br>• Parking<br>• Private space | High-priority positive constraints. |
| Avoid | Multi-select | Optional category | • Crowded<br>• Noisy<br>• Expensive<br>• Too far<br>• Outdoor heat<br>• Formal places<br>• Long waiting time | Negative constraints for Recommendation filtering. |

C. Partner Memory

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Memory Type | Single select per record | Required when adding memory | • Favorite food<br>• Favorite drink<br>• Favorite flower<br>• Favorite place<br>• Hobby | Each memory record = Type + Value. |
| Memory Value | Free text | Required when adding memory | • Example: Cheesecake<br>• Example: Tulip<br>• Example: Beach<br>• Example: Quiet places | Multiple values are allowed under the same Type. Edit/Delete supported. |

D. Daily / Quick Check-in

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Emotion | Single select | Required when submitting | • Good<br>• Okay<br>• Tired<br>• Sad<br>• Stressed<br>• Loved / Happy | User can skip the whole check-in. |
| Need | Single select | Required when submitting | • A hug<br>• Want to be listened to<br>• Care / Attention<br>• Space<br>• A little fun<br>• Time together | Latest submitted check-in can be included in AI context. |

E. Little Signals

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Signal | Single select | Required | • Thinking of you<br>• Need a hug<br>• Want to sit together<br>• Today is a bit rough<br>• Miss you<br>• Have something to tell you<br>• Want some care<br>• Want to talk tonight | Send to partner as quick emotional communication. |
| Optional message | Free text | Optional | • Max 100 characters | Partner receives the signal notification. |

F. AI Love Advisor - Quick Prompts

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Quick Prompt | Single tap to start chat | Optional | • What should I do for her today?<br>• Help me create a surprise<br>• What should I say?<br>• We have not gone on a date in a while<br>• She is sad | User can always ignore quick prompts and type free text. |

G. Place Data / Recommendation Tags

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Place Type | Single select per place | Required in dataset | • Restaurant<br>• Cafe<br>• Hotel<br>• Activity | Curated dataset for MVP. |
| Place Tags | Multi-select per place | Required as applicable | • Romantic<br>• Dessert<br>• Beach<br>• Quiet<br>• Cozy<br>• Outdoor<br>• Photography | Recommendation must match budget + at least 2 selected preference tags. |

H. Moment Feedback

| Field / Category | Selection Type | Required? | Options | Notes / Validation |
| --- | --- | --- | --- | --- |
| Feedback | Single select | Optional after completion | • Loved it<br>• Good<br>• Very happy / Sweet moment | Store against Completed Moment for future personalization. |

Current validation summary

• Partner Profile: Relationship + at least 2 preferences + 1 occasion + 1 budget.

• Partner Memory: Type + Value required; multiple values under the same Type are allowed.

• Daily Check-in: if submitted, exactly 1 Emotion + 1 Need; user may skip.

• Little Signal: 1 Signal required; optional message max 100 characters.

• AI Recommendation: must match budget and at least 2 partner preference tags.

• Place Data MVP: approximately 30-50 curated Da Nang places.
