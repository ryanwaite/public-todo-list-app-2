const waitPort = require('wait-port');
const fs = require('fs');
const { Pool } = require('pg');

const {
    POSTGRES_HOST: HOST,
    POSTGRES_HOST_FILE: HOST_FILE,
    POSTGRES_USER: USER,
    POSTGRES_USER_FILE: USER_FILE,
    POSTGRES_PASSWORD: PASSWORD,
    POSTGRES_PASSWORD_FILE: PASSWORD_FILE,
    POSTGRES_DB: DB,
    POSTGRES_DB_FILE: DB_FILE,
} = process.env;

let pool;

function readConfigValue(value, file) {
    return file ? fs.readFileSync(file, 'utf8').trim() : value;
}

async function init() {
    const host = readConfigValue(HOST, HOST_FILE);
    const user = readConfigValue(USER, USER_FILE);
    const password = readConfigValue(PASSWORD, PASSWORD_FILE);
    const database = readConfigValue(DB, DB_FILE);

    await waitPort({
        host,
        port: 5432,
        timeout: 10000,
        waitForDns: true,
    });

    pool = new Pool({
        max: 5,
        host,
        user,
        password,
        database,
    });

    await pool.query(
        'CREATE TABLE IF NOT EXISTS todo_items (id varchar(36), name varchar(255), completed boolean)',
    );
    console.log(`Connected to postgres db at host ${host}`);
}

async function teardown() {
    await pool.end();
}

async function getItems() {
    const result = await pool.query('SELECT * FROM todo_items');
    return result.rows;
}

async function getItem(id) {
    const result = await pool.query('SELECT * FROM todo_items WHERE id = $1', [
        id,
    ]);
    return result.rows[0];
}

async function storeItem(item) {
    await pool.query(
        'INSERT INTO todo_items (id, name, completed) VALUES ($1, $2, $3)',
        [item.id, item.name, item.completed],
    );
}

async function updateItem(id, item) {
    await pool.query(
        'UPDATE todo_items SET name = $1, completed = $2 WHERE id = $3',
        [item.name, item.completed, id],
    );
}

async function removeItem(id) {
    await pool.query('DELETE FROM todo_items WHERE id = $1', [id]);
}

module.exports = {
    init,
    teardown,
    getItems,
    getItem,
    storeItem,
    updateItem,
    removeItem,
};
