const mockQuery = jest.fn();
const mockEnd = jest.fn();
const mockPool = jest.fn(() => ({ query: mockQuery, end: mockEnd }));
const mockWaitPort = jest.fn();

jest.mock('pg', () => ({ Pool: mockPool }));
jest.mock('wait-port', () => mockWaitPort);

process.env.POSTGRES_HOST = 'postgres';
process.env.POSTGRES_USER = 'postgres';
process.env.POSTGRES_PASSWORD = 'secret';
process.env.POSTGRES_DB = 'todos';

const db = require('../../src/persistence/postgres');

const ITEM = {
    id: '7aef3d7c-d301-4846-8358-2a91ec9d6be3',
    name: 'Test',
    completed: false,
};

beforeEach(() => {
    mockQuery.mockReset();
    mockEnd.mockReset();
    mockPool.mockClear();
    mockWaitPort.mockReset();
});

test('it initializes the PostgreSQL pool and schema', async () => {
    await db.init();

    expect(mockWaitPort).toHaveBeenCalledWith({
        host: 'postgres',
        port: 5432,
        timeout: 10000,
        waitForDns: true,
    });
    expect(mockPool).toHaveBeenCalledWith({
        max: 5,
        host: 'postgres',
        user: 'postgres',
        password: 'secret',
        database: 'todos',
    });
    expect(mockQuery).toHaveBeenCalledWith(
        'CREATE TABLE IF NOT EXISTS todo_items (id varchar(36), name varchar(255), completed boolean)',
    );
});

test('it uses PostgreSQL parameters for item operations', async () => {
    mockQuery
        .mockResolvedValueOnce({ rows: [ITEM] })
        .mockResolvedValueOnce({ rows: [ITEM] });

    expect(await db.getItems()).toEqual([ITEM]);
    expect(await db.getItem(ITEM.id)).toEqual(ITEM);
    await db.storeItem(ITEM);
    await db.updateItem(ITEM.id, { ...ITEM, completed: true });
    await db.removeItem(ITEM.id);

    expect(mockQuery.mock.calls).toEqual([
        ['SELECT * FROM todo_items'],
        ['SELECT * FROM todo_items WHERE id = $1', [ITEM.id]],
        [
            'INSERT INTO todo_items (id, name, completed) VALUES ($1, $2, $3)',
            [ITEM.id, ITEM.name, false],
        ],
        [
            'UPDATE todo_items SET name = $1, completed = $2 WHERE id = $3',
            [ITEM.name, true, ITEM.id],
        ],
        ['DELETE FROM todo_items WHERE id = $1', [ITEM.id]],
    ]);
});

test('it closes the PostgreSQL pool', async () => {
    await db.teardown();
    expect(mockEnd).toHaveBeenCalled();
});
