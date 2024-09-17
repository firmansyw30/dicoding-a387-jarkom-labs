'use strict'

const express = require('express')

const PORT = 8000
const HOST = '0.0.0.0'

const app = express()
app.use(express.json()); // To parse JSON requests

/*
[ROUTE] '/'
[Response] => Hello world!
 */
app.get('/', (req, res) => {
    res.send('Hello world!\n')
})

/*
Optional [ROUTE] '/me'
[Response] => Dicoding username.
*/
app.get('/me', (req, res) => {
    res.send('dicoding_username : firmansyw30 \n')
})

app.get('/usr', (req, res) => {
    // Retrieve the username from query parameters or headers
    const username = req.query.username || req.headers.username;
    if (!username) {
        res.status(401).send('Unauthorized: No username provided');
    } else {
        res.send(`Hello, ${username}!\n`);
    }
})

app.listen(PORT, HOST)
console.log(`Running on http://${HOST}:${PORT}`)