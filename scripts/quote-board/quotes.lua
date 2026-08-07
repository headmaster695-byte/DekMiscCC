-- quote-board built-in quote pool
-- Required by quote-board.lua

local BUILTIN_QUOTES = {

  -- TIP ──────────────────────────────────────────────────────
  {
    "Mining with a wooden pickaxe is technically possible. However, so is walking to work. Neither is recommended.",
    "The Game", "TIP"
  },
  {
    "Coal can be used to fuel a furnace, power a campfire, or sit in a chest doing absolutely nothing. We support all three lifestyles.",
    "The Game", "TIP"
  },
  {
    "If you find yourself surrounded by hostile mobs, consider the time-honoured strategy of hoping someone else deals with it.",
    "The Game", "TIP"
  },
  {
    "Beds can be used to skip the night entirely. Time management experts consider this cheating.",
    "The Game", "TIP"
  },
  {
    "The shield blocks 100% of frontal attacks and 0% of attacks you did not see coming. Results may vary.",
    "The Game", "TIP"
  },
  {
    "Torches can be placed on most surfaces, except in the places where you actually need them.",
    "The Game", "TIP"
  },
  {
    "Turtles can automate most tasks, including the task of figuring out why your turtle is not working.",
    "The Game", "TIP"
  },
  {
    "Building a house before nightfall is recommended. Building a house before your seventh death is optional but encouraged.",
    "The Game", "TIP"
  },
  {
    "Gravel has a 10% chance to drop flint. The other 90% of the time it is the universe teaching you patience.",
    "The Game", "TIP"
  },
  {
    "If you dig straight down, you will fall into lava. This is not a bug. This is character development.",
    "The Game", "TIP"
  },
  {
    "Respawning is free, unlimited, and comes with complimentary existential dread.",
    "The Game", "TIP"
  },
  {
    "Dirt is the most common block in the game. This fact will not help you.",
    "The Game", "TIP"
  },

  -- DID YOU KNOW ─────────────────────────────────────────────
  {
    "Creepers were originally designed to be pigs. The pigs were not informed of this change.",
    "Probably True", "DID YOU KNOW"
  },
  {
    "The word 'Minecraft' contains the word 'mine'. The legal team has confirmed this was intentional.",
    "Legal Department", "DID YOU KNOW"
  },
  {
    "Diamonds were originally called 'shiny rocks'. Marketing insisted on the rebrand.",
    "Internal Memo, 2011", "DID YOU KNOW"
  },
  {
    "The Nether was added after a developer left the oven on. It was decided to keep it.",
    "Patch Notes (Unverified)", "DID YOU KNOW"
  },
  {
    "Endermen have never attacked first. All prior incidents are under internal review.",
    "Enderman PR Department", "DID YOU KNOW"
  },
  {
    "Herobrine has never existed in Minecraft. He has, however, been removed from the changelog forty-seven times.",
    "Changelogs, Various", "DID YOU KNOW"
  },
  {
    "Lava flows faster in the Nether. The lava is aware that you are wearing your best armour. The lava does not care.",
    "Nether Safety Commission", "DID YOU KNOW"
  },
  {
    "Skeletons are composed entirely of calcium. They are also composed entirely of the desire to ruin your evening.",
    "Skeleton Union, Local 7", "DID YOU KNOW"
  },
  {
    "The Ender Dragon has a name. Nobody in the game mentions it because it would undermine the atmosphere.",
    "Behind the Scenes, Vol. 3", "DID YOU KNOW"
  },
  {
    "Phantoms were added because players were sleeping too much. The developers considered therapy. They went with phantoms.",
    "Design Document, 2018", "DID YOU KNOW"
  },

  -- WISDOM ───────────────────────────────────────────────────
  {
    "Every great adventure begins with a single step. Unless that step is into a ravine. Then it ends there too.",
    "Ancient Proverb (Abridged)", "WISDOM"
  },
  {
    "The early miner gets the iron. The late miner gets the iron the early miner somehow missed.",
    "Miners' Almanac", "WISDOM"
  },
  {
    "Success is 10% inspiration and 90% not dying to the Skeleton that spawned directly behind you.",
    "Self-Help Book, Chapter 1", "WISDOM"
  },
  {
    "You miss 100% of the shots you do not take. You also miss approximately 43% of the ones you do. Aim for the body.",
    "Archery Instructor", "WISDOM"
  },
  {
    "A problem is just an opportunity you have not solved yet. Most problems remain problems.",
    "Motivational Poster", "WISDOM"
  },
  {
    "Believe in yourself. Unless you are about to dig straight down. Then believe in your backup saves.",
    "Therapy Session Notes", "WISDOM"
  },
  {
    "Hard work and dedication will get you far. A pickaxe enchanted with Fortune III will get you further.",
    "Career Counsellor", "WISDOM"
  },
  {
    "When life gives you gravel, smelt it into glass and build a structure nobody asked for.",
    "Survival Handbook, p. 47", "WISDOM"
  },
  {
    "The obstacle is the path. Unless the obstacle is lava. Then the path is around the lava.",
    "Zen and the Art of Spelunking", "WISDOM"
  },

  -- LOADING ──────────────────────────────────────────────────
  {
    "Loading... Please contemplate the decisions that brought you to this screen.",
    "The Loading Screen", "LOADING"
  },
  {
    "The world is being generated. This takes time because quality takes time. Also because it is very large.",
    "The Loading Screen", "LOADING"
  },
  {
    "Your progress has been saved. Your decisions, however, are permanent.",
    "Autosave Complete", "LOADING"
  },
  {
    "The server is thinking. Please do not disturb the server while it thinks.",
    "Server Administration", "LOADING"
  },
  {
    "If this is taking too long, it is not a bug. It is an opportunity for self-reflection.",
    "Support FAQ", "LOADING"
  },

  -- QUOTE (real-life: misquotations, slight rewrites, absurd context) ───────
  {
    "Elementary, my dear Watson.",
    "Sherlock Holmes — never written by Doyle", "QUOTE"
  },
  {
    "Play it again, Sam.",
    "Casablanca — nobody in the film says this", "QUOTE"
  },
  {
    "Houston, we have a problem.",
    "Apollo 13 — they said 'we've had a problem'", "QUOTE"
  },
  {
    "Let them eat cake.",
    "Marie Antoinette — predates her by about thirty years", "QUOTE"
  },
  {
    "I cannot tell a lie.",
    "George Washington — invented by his biographer after his death", "QUOTE"
  },
  {
    "The definition of insanity is doing the same thing over and over and expecting different results.",
    "Einstein — he never said this. Neither did Franklin or Twain.", "QUOTE"
  },
  {
    "Luke, I am your father.",
    "Darth Vader — the actual line is 'No, I am your father'", "QUOTE"
  },
  {
    "If you build it, they will come.",
    "Field of Dreams — the line is 'he will come'", "QUOTE"
  },
  {
    "Blood is thicker than water.",
    "The full proverb means the opposite. You are welcome.", "QUOTE"
  },
  {
    "Mirror, mirror on the wall, who is the fairest of them all?",
    "Snow White — it is 'Magic mirror on the wall'", "QUOTE"
  },
  {
    "I think, therefore I am.",
    "Rene Descartes — after doubting the existence of everything, including himself", "QUOTE"
  },
  {
    "To be, or not to be, that is the question.",
    "Shakespeare, Hamlet — Hamlet never receives an answer", "QUOTE"
  },
  {
    "The only thing we have to fear is fear itself.",
    "Franklin D. Roosevelt — he also had quite a lot to say about the economy", "QUOTE"
  },
  {
    "Float like a butterfly, sting like a bee.",
    "Muhammad Ali — also sound tactical advice for most conflicts", "QUOTE"
  },
  {
    "Be yourself; everyone else is already taken.",
    "Oscar Wilde, allegedly — he probably did not say this", "QUOTE"
  },
  {
    "The reports of my death are greatly exaggerated.",
    "Mark Twain — he wrote 'the report... was an exaggeration'", "QUOTE"
  },
  {
    "That's one small step for man, one giant leap for mankind.",
    "Neil Armstrong — he meant 'for a man'; the 'a' was inaudible", "QUOTE"
  },
  {
    "The pen is mightier than the sword.",
    "Bulwer-Lytton — who also wrote the worst opening sentence in literature", "QUOTE"
  },
  {
    "Not all those who wander are lost.",
    "J.R.R. Tolkien — some of them are definitely lost", "QUOTE"
  },
  {
    "It was a dark and stormy night; the rain fell in torrents.",
    "Edward Bulwer-Lytton — widely considered the worst opening sentence ever published", "QUOTE"
  },
  {
    "In this world nothing can be said to be certain, except death and taxes.",
    "Benjamin Franklin — he found this so depressing he wrote it in a letter", "QUOTE"
  },
  {
    "Well-behaved women seldom make history.",
    "Laurel Thatcher Ulrich — originally a footnote in an academic paper", "QUOTE"
  },
  {
    "I am not afraid of an army of lions led by a sheep; I am afraid of an army of sheep led by a lion.",
    "Attributed to Alexander the Great — almost certainly not him", "QUOTE"
  },
  {
    "It is a truth universally acknowledged that a single man in possession of a good fortune must be in want of a wife.",
    "Jane Austen, Pride and Prejudice — she was being sarcastic", "QUOTE"
  },
  {
    "All animals are equal, but some animals are more equal than others.",
    "George Orwell, Animal Farm — intended as satire; adopted as policy", "QUOTE"
  },
  {
    "Power tends to corrupt, and absolute power corrupts absolutely.",
    "Lord Acton, 1887 — a historian, not speaking hypothetically", "QUOTE"
  },
  {
    "Ask not what your country can do for you; ask what you can do for your country.",
    "John F. Kennedy — the answer to the second question was not relaxing", "QUOTE"
  },
  {
    "In the beginning God created the heavens and the earth.",
    "Genesis 1:1 — subsequent events are disputed", "QUOTE"
  },
  {
    "The only way to do great work is to love what you do.",
    "Steve Jobs — he also had an extensive legal and marketing team", "QUOTE"
  },
  {
    "History is written by the victors.",
    "Widely misattributed to Churchill — it was not him", "QUOTE"
  },
  {
    "We have nothing to fear but fear itself. And spiders. But mainly fear.",
    "Franklin D. Roosevelt (amended by popular consensus)", "QUOTE"
  },
  {
    "I have a dream.",
    "Martin Luther King Jr. — the full speech had considerably more detail", "QUOTE"
  },
}


return BUILTIN_QUOTES
