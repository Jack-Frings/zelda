--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GAME_OBJECT_DEFS = {
    ['switch'] = {
        type = 'switch',
        texture = 'switches',
        frame = 2,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'unpressed',
        states = {
            ['unpressed'] = {
                frame = 2
            },
            ['pressed'] = {
                frame = 1
            }
        }
    },
    ['bullet'] = { --Ground bullet to pick up
        type = 'bullet',
        texture = 'bullet',
        frame = 1,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'default',
        states = {
            ['default'] = {
                frame = 1
            }
        }
    }
}