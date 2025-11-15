Config = {}


Config.PriestJob = 'priest'


Config.Scenario = 'WORLD_HUMAN_WRITE_NOTEBOOK'

-- Healing settings
Config.Blessing = {
    radius = 10.0, -- Radius in meters
    healAmount = 25, -- Amount of health to restore
    cooldown = 30000, -- Cooldown in milliseconds (30 seconds)
}

-- Hymn settings
Config.Hymns = {
    enabled = true,
    radius = 30.0, -- How far the hymn can be heard (in meters)
    volume = 0.5, -- Volume (0.0 - 1.0)
    songs = {
        {
            title = 'Nothing but the blood',
            description = 'A classic hymn of redemption',
            url = 'https://www.youtube.com/watch?v=-Cvv5uDOzvM&list=PLCdtzHEdiJSqBjzz5FVpap2iL37bfi2lW' -- Replace with your URL
        },
		{
            title = 'old west choir',
            description = 'A classic hymn of redemption',
            url = 'https://www.youtube.com/watch?v=_EDBqVslqc0' -- Replace with your URL
        },
        {
            title = 'Custom Hymn',
            description = 'Play a custom hymn from URL',
            custom = true
        }
    }
}

-- Preaching dialogue options
Config.Sermons = {
    {
        title = 'Sermon on Faith',
        description = 'Preach about the power of faith',
        message = 'Gather round, brothers and sisters! In these harsh and unforgiving lands, it is faith that sustains us. When the storms rage and the darkness seems endless, remember that faith can move mountains! The Lord does not promise us an easy path, but He promises to walk beside us. Let your faith be the compass that guides you through the wilderness of doubt, the anchor that holds you steady in the tempest of despair. For it is written, those who believe shall never walk alone!'
    },
    {
        title = 'Sermon on Hope',
        description = 'Inspire hope in those who listen',
        message = 'My dear congregation, in these dark and troubled times, when lawlessness runs rampant and good men fall to temptation, we must not lose hope! Hope is the light that pierces through the darkest shadows of our souls. It is the dawn that follows the longest night. Though we may stumble, though we may fall, hope lifts us up again. Look not to the darkness that surrounds you, but to the light of the Lord that shines eternal. For where there is hope, there is life. Where there is hope, there is salvation!'
    },
    {
        title = 'Sermon on Redemption',
        description = 'Speak about redemption and forgiveness',
        message = 'Listen well, you weary souls! I know many of you carry the weight of your past sins like chains upon your hearts. You may think yourselves beyond saving, too far gone down the path of wickedness. But I tell you this - no matter how dark your deeds, no matter how heavy your burden, redemption is always within reach for those who truly seek it! The Lord does not turn away the repentant sinner. He welcomes them with open arms! It is never too late to change your ways, to seek forgiveness, and to walk the righteous path. Today can be the first day of your salvation!'
    },
    {
        title = 'Sermon on Charity',
        description = 'Encourage charity and kindness',
        message = 'Brothers and sisters, in this harsh frontier where every man seems to fend only for himself, we must remember the sacred duty of charity! Look around you - see your neighbors struggling, your fellow travelers in need. The Lord asks not for grand gestures, but for simple kindness. Share your bread with the hungry, offer shelter to the cold, extend your hand to those who have fallen. For charity is the greatest virtue of all! What profit is there in gaining the whole world if we lose our humanity? Let us care for one another as the Lord cares for us. In giving, we receive. In loving, we are loved!'
    },
    {
        title = 'Sermon on Courage',
        description = 'Inspire courage in the faithful',
        message = 'Hear me now, faithful ones! This land tests our mettle every single day. Outlaws, hardship, and trials that would break lesser souls. But we are not lesser souls! We are children of the Almighty, and He has given us the strength to endure! Stand strong in the face of adversity, for the Lord walks with the courageous! Fear not the outlaws or the lawless, for righteousness is our shield and faith our sword. When you face down evil, know that you do not stand alone. The Lord stands beside you, His hand upon your shoulder, His light before you. Be brave, be bold, be righteous!'
    },
    {
        title = 'Sermon on Judgment',
        description = 'Warn about divine judgment',
        message = 'My congregation, we live in times where men believe they can escape the consequences of their actions. They rob, they kill, they lie and cheat, thinking no one sees. But I tell you - the Lord sees all! Every deed, every sin, every transgression is recorded in the Book of Life. The day of judgment will come for us all, when we must stand before the Almighty and account for our lives. Will you be found wanting? Will your deeds be weighed and found light? Or will you stand proud in righteousness, knowing you lived according to His word? Choose wisely how you live, for eternity is a long time to regret!'
    },
    {
        title = 'Sermon on Forgiveness',
        description = 'Teach the importance of forgiveness',
        message = 'Beloved souls, in this land of revenge and retribution, I bring you a message that may be hard to hear - you must learn to forgive! I know, I know... someone has wronged you, hurt you, taken from you. The desire for vengeance burns hot in your chest. But holding onto hatred is like drinking poison and expecting the other person to die! Forgiveness does not mean forgetting, nor does it mean allowing evil to go unpunished. It means freeing yourself from the chains of bitterness. As the Lord forgives us our trespasses, so must we forgive those who trespass against us. Let go of your anger, and find peace!'
    },
    {
        title = 'Sermon on Humility',
        description = 'Speak about the virtue of humility',
        message = 'Listen to me, proud men and women of the frontier! You may have wealth, you may have power, you may be the fastest gun or the shrewdest merchant. But what does it profit you if you are puffed up with pride? The Lord resists the proud but gives grace to the humble! Remember, no matter how high you rise, you are still dust and to dust you shall return. The richest man and the poorest beggar stand equal before God. Let humility be your guide. Serve others before yourself. Acknowledge that all your blessings come from the Almighty, not your own hand. In humility, there is wisdom. In humility, there is peace!'
    },
    {
        title = 'Sermon on Temperance',
        description = 'Preach against excess and vice',
        message = 'My dear flock, I see many of you stumbling from the saloons, your coins wasted on whiskey and cards, your lives consumed by vice! The pleasures of the flesh are fleeting, but their consequences are lasting! The Lord calls us to temperance - to moderation in all things. Yes, you may enjoy life, but do not let enjoyment become enslavement! How many families have been destroyed by the bottle? How many fortunes lost at the poker table? How many souls damned by lustful pursuits? Control your desires before they control you! Master your appetites before they master you! Walk the path of temperance and find true freedom!'
    },
    {
        title = 'Sermon on Perseverance',
        description = 'Encourage endurance through hardship',
        message = 'Brothers and sisters, I know life on this frontier is hard! The sun beats down mercilessly, the land is unforgiving, and trials seem endless. Many of you want to give up, to surrender to despair. But I say to you - persevere! The Lord did not bring you this far to abandon you now! Every great triumph is born from great struggle. The seed must be buried in darkness before it can grow toward the light. Your hardships are not punishments, but refinements! Like gold purified in fire, you are being made stronger, better, more worthy! Do not give up when you are so close to breakthrough. Keep pushing forward, keep fighting the good fight, and your reward shall be great!'
    },
    {
        title = 'Custom Sermon',
        description = 'Speak your own words',
        custom = true
    }
}


Config.MenuOptions = {
    {
        title = 'Read Bible',
        description = 'Read from the holy scripture',
        icon = 'book-open-reader',
        action = 'read'
    },
    {
        title = 'Hold Bible',
        description = 'Hold the bible while standing',
        icon = 'hand-holding',
        action = 'hold'
    },
    {
        title = 'Preach',
        description = 'Preach to nearby people',
        icon = 'church',
        action = 'preach'
    },
    {
        title = 'Play Hymn',
        description = 'Play a sacred hymn for all to hear',
        icon = 'music',
        action = 'hymn'
    },
    {
        title = 'Bless',
        description = 'Bless and heal nearby people',
        icon = 'hands-praying',
        action = 'bless'
    },
    {
        title = 'Give Bible',
        description = 'Give a bible to another person',
        icon = 'gift',
        action = 'give'
    },
    {
        title = 'Stop',
        description = 'Put the bible away',
        icon = 'xmark',
        action = 'stop'
    }
}


Config.Messages = {
    reading = 'Reading the holy scripture...',
    holding = 'Holding the bible...',
    preaching = 'Preaching to the congregation...',
    blessing = 'Blessing those around you...',
    stopped = 'You put the bible away',
    notPriest = 'Only priests can use the bible!',
    blessed = 'You have been blessed and healed!',
    blessedSelf = 'You blessed %d people nearby (including yourself)',
    cooldown = 'You must wait before blessing again',
    noNearby = 'There is no one nearby to bless',
    bibleGiven = 'You gave a bible to %s',
    bibleReceived = 'You received a holy bible from Priest %s',
    noPlayers = 'No players online to give bible to',
    hymnPlaying = 'Now playing: %s',
    hymnStopped = 'The hymn has ended',
    hymnAlreadyPlaying = 'A hymn is already playing',
    xsoundNotFound = 'xsound resource not found! Hymns require xsound to work.'
}