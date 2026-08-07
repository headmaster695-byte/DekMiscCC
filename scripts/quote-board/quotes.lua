-- quote-board built-in quote pool
-- Required by quote-board.lua

local BUILTIN_QUOTES = {

  -- TIP ──────────────────────────────────────────────────────
  {
    "Never dig straight down. Everyone knows this. Everyone does it anyway.",
    "The Game", "TIP"
  },
  {
    "A wooden pickaxe can mine stone. It will also make you question several life choices.",
    "The Game", "TIP"
  },
  {
    "Keep a water bucket on your hotbar. One day you will understand why, and you will not enjoy that day.",
    "The Game", "TIP"
  },
  {
    "Creepers hiss before they explode. This is considered fair warning.",
    "The Game", "TIP"
  },
  {
    "If your house has no door, you do not have a house. You have a waiting room for zombies.",
    "The Game", "TIP"
  },
  {
    "Torches prevent mobs from spawning. They do not prevent you from forgetting where you put them.",
    "The Game", "TIP"
  },
  {
    "Lava and water make cobblestone. Lava and you make a new world seed.",
    "The Game", "TIP"
  },
  {
    "Always carry food. Starving to death next to a chest full of steak is a recognised tradition.",
    "The Game", "TIP"
  },
  {
    "Skeletons can shoot you from further away than you think. They know this. You will learn.",
    "The Game", "TIP"
  },
  {
    "Beds set your spawn point. They do not set it somewhere sensible.",
    "The Game", "TIP"
  },
  {
    "Falling into a ravine is not a mining strategy. It is, however, a very fast one.",
    "The Game", "TIP"
  },
  {
    "Name tags stop mobs from despawning. They do not stop you from naming a creeper 'friend'.",
    "The Game", "TIP"
  },
  {
    "Boats are faster than walking. Boats are also somehow worse at going where you intended.",
    "The Game", "TIP"
  },
  {
    "Mark your mineshaft entrance. Future you is an idiot and will thank you.",
    "The Game", "TIP"
  },

  -- DID YOU KNOW ─────────────────────────────────────────────
  {
    "Creepers were meant to be pigs. Notch got the height and width swapped. Nobody fixed the attitude.",
    "Dev lore", "DID YOU KNOW"
  },
  {
    "Endermen pick up blocks. They put them back somewhere worse.",
    "Field notes", "DID YOU KNOW"
  },
  {
    "Herobrine has been removed from the game more times than he was ever in it.",
    "Changelogs", "DID YOU KNOW"
  },
  {
    "Phantoms spawn if you refuse to sleep. The game would like a word about your work-life balance.",
    "Update 1.13", "DID YOU KNOW"
  },
  {
    "The Nether roof is solid bedrock. Players treat this as a suggestion.",
    "Server logs", "DID YOU KNOW"
  },
  {
    "Cats scare creepers. Creepers scare you. The cats know what they are doing.",
    "Natural history", "DID YOU KNOW"
  },
  {
    "Villagers will trade you enchanted books. They will not explain why a librarian needs twenty rotten flesh.",
    "Economics", "DID YOU KNOW"
  },
  {
    "Silverfish hide in stone. You will discover this by punching the wrong block at the worst time.",
    "Stronghold brochure", "DID YOU KNOW"
  },
  {
    "The Ender Dragon destroys end stone. She also destroys your sense of direction.",
    "End tourism board", "DID YOU KNOW"
  },
  {
    "Axolotls will fight drowned for you. They will also vanish the moment you look away from them.",
    "Pet ownership", "DID YOU KNOW"
  },
  {
    "Piglins hate when you open chests near them. They are fine with you dying near them.",
    "Nether etiquette", "DID YOU KNOW"
  },
  {
    "A compass points to your world spawn. It does not point to where you left your diamonds.",
    "Navigation", "DID YOU KNOW"
  },

  -- WISDOM ───────────────────────────────────────────────────
  {
    "Measure twice, mine once. Or don't. The ravine was always there.",
    "Anonymous miner", "WISDOM"
  },
  {
    "Fortune favours the bold. Also anyone holding a Fortune III pickaxe.",
    "Enchanting table graffiti", "WISDOM"
  },
  {
    "It is better to have a shield and not need it than to explain to your friends why you are naked again.",
    "Arena advice", "WISDOM"
  },
  {
    "The real treasure was the friends we made along the way. The diamonds help though.",
    "Chest plaque", "WISDOM"
  },
  {
    "Leave the caves before dark. Or don't. The caves do not care about your schedule.",
    "Surface dweller proverb", "WISDOM"
  },
  {
    "Build above ground if you want to live. Dig below ground if you want iron. Do both if you want problems.",
    "Settlement guide", "WISDOM"
  },
  {
    "A redstone engineer says it will take five minutes. Bring a packed lunch.",
    "Project management", "WISDOM"
  },
  {
    "Never trust a map drawn by someone who died making it.",
    "Cartographers' union", "WISDOM"
  },
  {
    "You can beat the Ender Dragon. You cannot beat the storage system you built at hour two.",
    "Late-game confession", "WISDOM"
  },
  {
    "Share your base coordinates with people you trust. Hide a second stash anyway.",
    "Multiplayer survival", "WISDOM"
  },

  -- LOADING ──────────────────────────────────────────────────
  {
    "Generating terrain... burying your house under a floating island...",
    "Worldgen", "LOADING"
  },
  {
    "Loading chunks. Looking busy.",
    "Server", "LOADING"
  },
  {
    "Connecting to server... blaming your internet...",
    "Client", "LOADING"
  },
  {
    "Building terrain. Please wait. Or don't. We can't see you either way.",
    "Worldgen", "LOADING"
  },
  {
    "Saving world... pretending this always works...",
    "Autosave", "LOADING"
  },
  {
    "Still loading. Your sheep are fine. Probably.",
    "Server", "LOADING"
  },
  {
    "Preparing spawn area. Creepers have already moved in.",
    "Worldgen", "LOADING"
  },

  -- QUOTE ────────────────────────────────────────────────────
  -- Famous lines, slightly off, or attributed with a straight face
  {
    "Elementary, my dear Watson.",
    "Sherlock Holmes (he never said this)", "QUOTE"
  },
  {
    "Play it again, Sam.",
    "Casablanca (wrong film, wrong line)", "QUOTE"
  },
  {
    "Houston, we have a problem.",
    "Apollo 13 (close enough for Hollywood)", "QUOTE"
  },
  {
    "Let them eat cake.",
    "Marie Antoinette (said by someone else, decades earlier)", "QUOTE"
  },
  {
    "Luke, I am your father.",
    "Darth Vader (still wrong after forty years)", "QUOTE"
  },
  {
    "The definition of insanity is doing the same thing over and over and expecting different results.",
    "Albert Einstein (never said it; still printed on mugs)", "QUOTE"
  },
  {
    "I cannot tell a lie.",
    "George Washington (his biographer told that one)", "QUOTE"
  },
  {
    "If you build it, they will come.",
    "Field of Dreams (he said 'he', not 'they')", "QUOTE"
  },
  {
    "Mirror, mirror on the wall...",
    "Evil Queen (it's 'Magic mirror', but nobody cares)", "QUOTE"
  },
  {
    "Money is the root of all evil.",
    "Popular Bible paraphrase (missed the 'love of' part)", "QUOTE"
  },
  {
    "Blood is thicker than water.",
    "Proverb (the longer version argues the opposite)", "QUOTE"
  },
  {
    "The reports of my death are greatly exaggerated.",
    "Mark Twain (paraphrased himself into a better line)", "QUOTE"
  },
  {
    "Be yourself; everyone else is already taken.",
    "Oscar Wilde (probably not; still sounds like him)", "QUOTE"
  },
  {
    "That's one small step for man...",
    "Neil Armstrong (the 'a' fell into the static)", "QUOTE"
  },
  {
    "Not all those who wander are lost.",
    "Tolkien (some of them are though)", "QUOTE"
  },
  {
    "History is written by the victors.",
    "Winston Churchill (nope) / Napoleon (also nope)", "QUOTE"
  },
  {
    "I have not yet begun to fight.",
    "John Paul Jones (said while his ship was on fire)", "QUOTE"
  },
  {
    "We few, we happy few, we band of brothers.",
    "Henry V (via Shakespeare; morale improved immediately)", "QUOTE"
  },
  {
    "The pen is mightier than the sword.",
    "Bulwer-Lytton (same man who opened with a dark and stormy night)", "QUOTE"
  },
  {
    "I think, therefore I am.",
    "Descartes (after deciding everything else was suspicious)", "QUOTE"
  },
  {
    "To fail to prepare is to prepare to fail.",
    "Attributed to everyone who has ever run a meeting", "QUOTE"
  },
  {
    "There is no such thing as bad weather, only bad clothing.",
    "Norwegian proverb (written somewhere warm)", "QUOTE"
  },
  {
    "An army marches on its stomach.",
    "Napoleon (or Frederick the Great; historians still arguing)", "QUOTE"
  },
  {
    "Speak softly and carry a big stick.",
    "Theodore Roosevelt (he meant it literally enough)", "QUOTE"
  },
  {
    "The only thing we have to fear is fear itself.",
    "FDR (spiders were implied)", "QUOTE"
  },
  {
    "All that glitters is not gold.",
    "Shakespeare (also applies to pyrite and bad trades)", "QUOTE"
  },
  {
    "Rome wasn't built in a day.",
    "Medieval proverb (used mostly by people missing deadlines)", "QUOTE"
  },
  {
    "Don't count your chickens before they hatch.",
    "Aesop-ish advice (ignored by every farmer with a plan)", "QUOTE"
  },
  {
    "A journey of a thousand miles begins with a single step.",
    "Laozi (the other 999 miles are mostly gravel)", "QUOTE"
  },
  {
    "Keep your friends close and your enemies closer.",
    "Sun Tzu / The Godfather (pick your favourite)", "QUOTE"
  },
}


return BUILTIN_QUOTES
