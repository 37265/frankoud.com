CREATE DATABASE IF NOT EXISTS InAudible;

USE InAudible;

CREATE TABLE IF NOT EXISTS Customer (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(52) NOT NULL,
    last_name VARCHAR(52) NOT NULL
);

INSERT INTO Customer (first_name, last_name) VALUES
    ("Frank", "Oud"),
    ("Some", "Guy"),
    ("Other", "Guy");
