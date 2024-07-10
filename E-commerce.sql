create database ecommerce;
use ecommerce;

create table clients(
    idClient int auto_increment primary_key,
    Fname varchar(10),
    Minit char(3),
    Lname varchar(20),
    CPF char(11) not null,
    Address varchar(30),
    constrain unique_cpf_client unique (CPF)
);

alter table clients auto_increment=1;

create table product(
    idProduct int auto_increment primary_key,
    Pname varchar(10) not null,
    Classification_kids boolean default false,
    category enum('Electrônico', 'Vestimenta', 'Brinquedos', 'Alimentos', 'Móveis') not null,
    avaliação float default 0,
    size varchar(10)
);

create table payments(
    idClient int,
    idPayment int,
    typePayment enum('Boleto', 'Cartão', 'Dois cartões'),
    limitAvailable float,
    primary_key(idClient, idPayment)
);

create table orders(
    idOrder int auto_increment primary_key,
    idOrderClient int,
    orderStatus enum('Cancelado', 'Confirmado', 'Em processamento') default 'Em processamento',
    orderDescription varchar(255),
    sendValue float default 10,
    paymentCash boolean default false,
    idClient INT,
    idPayment INT,
    constrain fk_orders_client foreign key (idOrderClient) references clients(idClient),
    constrain fk_orders_payment foreign key (idClient, idPayment) references payments(idClient, idPayment)
);

create table productStorage(
    idProdStorage int auto_increment primary_key,
    storageLocation varchar(255),
    quantity int default 0
);

create table supplier(
    idSupplier int auto_increment primary_key,
    SocialName varchar(255) not null,
    CNPJ char(15) not null,
    concat char(11) not null,
    constrain unique_supplier unique (CNPJ)
);

create table seller(
    idSeller int auto_increment primary_key,
    SocialName varchar(255) not null,
    AbstName varchar(255),
    CNPJ char(15),
    CPF char(9),
    location varchar(255),
    concat char(11) not null,
    constrain unique_cnpj_seller unique (CNPJ),
    constrain unique_cpf_seller unique (CPF)
);

create table productSeller(
    idPseller int,
    idPproduct int,
    prodQuantity int default 1,
    primary_key(idPseller, idPproduct),
    constrain fk_product_seller foreign key (idPseller) references seller(idSeller),
    constrain fk_product_product foreign key (idPproduct) references product(idProduct)
);

create table productOrder(
    idPOproduct int,
    idPOorder int,
    poQuantity int default 1,
    poStatus enum('Disponível', 'Sem estoque') default 'Disponível',
    primary_key(idPOproduct, idPOorder),
    constrain fk_product_order_product foreign key (idPOproduct) references product(idProduct),
    constrain fk_product_order_order foreign key (idPOorder) references orders(idOrder)
);

create table storageLocation(
    idLproduct int,
    idLstorage int,
    location varchar(255) not null,
    primary_key(idLproduct, idLstorage),
    constrain fk_storage_location_product foreign key (idLproduct) references product(idProduct),
    constrain fk_storage_location_storage foreign key (idLstorage) references productStorage(idProdStorage)
);

create table productSupplier(
    idPsSupplier int,
    idPsProduct int,
    quantity int not null,
    primary_key(idPsSupplier, idPsProduct),
    constrain fk_product_supplier_supplier foreign key (idPsSupplier) references supplier(idSupplier),
    constrain fk_product_supplier_product foreign key (idPsProduct) references product(idProduct)
);

-- Desabilitar o autocommit
SET autocommit = 0;

-- Transação
START TRANSACTION;

INSERT INTO clients (Fname, Minit, Lname, CPF, Address) 
VALUES ('João', 'A', 'Silva', '12345678901', 'Rua A, 123');

INSERT INTO product (Pname, Classification_kids, category, avaliação, size) 
VALUES ('Camiseta', false, 'Vestimenta', 4.5, 'M');

INSERT INTO seller (SocialName, AbstName, CNPJ, CPF, location, concat) 
VALUES ('Vendedor B', 'VendedorB', '12345678901234', '987654321', 'Rua B, 456', '98765432101');
COMMIT;
ROLLBACK;

-- Transação em uma procedure
DELIMITER $$
CREATE PROCEDURE insert_data_transaction()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro na transação. Rollback realizado.';
    END;
    
    START TRANSACTION;

    SAVEPOINT sp1;
    INSERT INTO clients (Fname, Minit, Lname, CPF, Address) 
    VALUES ('Maria', 'B', 'Oliveira', '23456789012', 'Rua B, 456');

    SAVEPOINT sp2;
    INSERT INTO product (Pname, Classification_kids, category, avaliação, size) 
    VALUES ('Laptop', false, 'Eletrônico', 4.8, '15"');

    IF (SELECT avaliação FROM product WHERE Pname = 'Laptop') < 0 OR (SELECT avaliação FROM product WHERE Pname = 'Laptop') > 5 THEN
        ROLLBACK TO sp2;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avaliação inválida para o produto. Rollback parcial realizado.';
    END IF;

    SAVEPOINT sp3;
    INSERT INTO payments (idClient, idPayment, typePayment, limitAvailable) 
    VALUES (2, 2, 'Boleto', 500.0);

    INSERT INTO orders (idOrderClient, orderStatus, orderDescription, sendValue, paymentCash, idClient, idPayment) 
    VALUES (2, 'Confirmado', 'Compra de um laptop', 10.0, false, 2, 2);

    IF (SELECT idClient FROM orders WHERE idOrderClient = 2) != (SELECT idClient FROM payments WHERE idPayment = 2) THEN
        ROLLBACK TO sp3;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente e pagamento não correspondem. Rollback parcial realizado.';
    END IF;

    COMMIT;
END$$
DELIMITER ;

-- Backup
mysqldump --user root --password --databases ecommerce > ecommerce_backup.sql

--Recovery
mysql --user root --password < ecommerce_backup.sql