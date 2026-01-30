CREATE DATABASE IF NOT EXISTS InAudible
  CHARACTER SET utf8mb4;

USE InAudible;

CREATE USER IF NOT EXISTS 'inaudible'@'%' IDENTIFIED BY 'inaudible_pw';

GRANT ALL PRIVILEGES ON InAudible.* TO 'inaudible'@'%';

FLUSH PRIVILEGES;

CREATE TABLE IF NOT EXISTS Address (
  id INT AUTO_INCREMENT,
  street VARCHAR(30) NOT NULL, /* The longest possible street name is 28 characters */
  postcode VARCHAR(10) NOT NULL, /* The longest possible postcode is ten characters */
  house_number VARCHAR(10) NOT NULL,
  city VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS Plan (
  id INT AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  billing_interval ENUM('yearly', 'monthly') NOT NULL,
  base_price FLOAT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS Discount (
  id INT AUTO_INCREMENT,
  type ENUM('percentage', 'flat') NOT NULL,
  name VARCHAR(255) NOT NULL,
  amount FLOAT NOT NULL,
  valid_from DATE NOT NULL,
  valid_to DATE,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS Customer (
  id INT AUTO_INCREMENT,
  full_name VARCHAR(255) NOT NULL,
  email_address VARCHAR(255) NOT NULL,
  birth_date DATE NOT NULL,
  status ENUM('active', 'suspended', 'deleted', 'to_delete') NOT NULL,
  created_at TIMESTAMP NOT NULL,
  deleted TINYINT(1) DEFAULT (0),
  deleted_at TIMESTAMP,
  address_id INT,
  PRIMARY KEY (id),
  UNIQUE (email_address), /* Because e-mail addresses will likely be used for login*/
  FOREIGN KEY (address_id) 
    REFERENCES Address(id)
    ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS Payment (
  id INT AUTO_INCREMENT,
  payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  amount FLOAT NOT NULL,
  method ENUM('credit_card', 'bank_transfer', 'invoice') NOT NULL,
  status ENUM('pending', 'paid', 'failed', 'refunded') NOT NULL,
  customer_id INT NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (customer_id) 
    REFERENCES Customer(id)
    ON DELETE NO ACTION
);

CREATE TABLE Subscription (
  id INT AUTO_INCREMENT,
  start_date DATE NOT NULL,
  end_date DATE,
  status ENUM('active', 'cancelled', 'paused', 'expired') NOT NULL,
  customer_id INT NOT NULL,
  plan_id INT NOT NULL,
  discount_id INT,
  PRIMARY KEY (id),
  FOREIGN KEY (customer_id) 
    REFERENCES Customer(id),
    ON DELETE NO ACTION
  FOREIGN KEY (plan_id) 
    REFERENCES Plan(id),
    ON DELETE NO ACTION
  FOREIGN KEY (discount_id) 
    REFERENCES Discount(id)
    ON DELETE SET NULL
);