-- ZERO TRUST CAGE - Gaming Database Schema

CREATE TABLE player_wallets (
    id SERIAL PRIMARY KEY,
    player_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    balance DECIMAL(15,2) DEFAULT 0.00,
    vip_level VARCHAR(20) DEFAULT 'BRONZE',
    account_status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_transaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES player_wallets(id),
    amount DECIMAL(15,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    game_type VARCHAR(50),
    table_number VARCHAR(10),
    authorized_by VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50),
    username VARCHAR(100),
    source_ip VARCHAR(45),
    action VARCHAR(200),
    result VARCHAR(20),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO player_wallets (player_name, email, balance, vip_level) VALUES
('James Bond', 'bond@mi6.gov.uk', 1000000.00, 'PLATINUM'),
('Danny Ocean', 'docean@vegas.com', 500000.00, 'GOLD'),
('Rusty Ryan', 'rusty@eleven.com', 250000.00, 'SILVER'),
('Linus Caldwell', 'linus@heist.com', 100000.00, 'BRONZE'),
('Saul Bloom', 'saul@casino.com', 750000.00, 'GOLD');

INSERT INTO transactions (player_id, amount, transaction_type, game_type, table_number, authorized_by) VALUES
(1, 50000.00, 'BET', 'Baccarat', 'T-001', 'dealer_bond'),
(1, 75000.00, 'WIN', 'Baccarat', 'T-001', 'dealer_bond'),
(2, 25000.00, 'BET', 'Poker', 'T-005', 'dealer_ocean'),
(2, 100000.00, 'WIN', 'Poker', 'T-005', 'dealer_ocean'),
(3, 10000.00, 'BET', 'Blackjack', 'T-010', 'dealer_ryan'),
(3, 5000.00, 'LOSS', 'Blackjack', 'T-010', 'dealer_ryan'),
(4, 15000.00, 'BET', 'Roulette', 'T-015', 'dealer_caldwell'),
(5, 200000.00, 'WITHDRAWAL', 'N/A', 'CAGE', 'cage_manager');

INSERT INTO audit_log (event_type, username, source_ip, action, result) VALUES
('LOGIN', 'cage_manager', '172.22.0.20', 'Accessed player_wallets', 'SUCCESS'),
('LOGIN', 'dealer1', '172.21.0.10', 'Accessed transactions', 'SUCCESS'),
('LOGIN', 'unknown', '172.20.0.100', 'Attempted direct DB access', 'BLOCKED');
