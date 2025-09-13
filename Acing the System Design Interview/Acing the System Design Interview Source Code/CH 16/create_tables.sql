CREATE TABLE Image ( 
  CdnPath    VARCHAR(255) PRIMARY KEY,  
  PhotoKey   VARCHAR(255) NOT NULL,  
  Resolution ENUM('thumbnail', 'hd')  
  UserId     VARCHAR(255) NOT NULL,  
  Public     BOOLEAN NOT NULL DEFAULT 1,  
  INDEX thumbnail (Resolution, UserId)  
);  

CREATE TABLE ImageDir (  
  CdnDir VARCHAR(255),  
  UserId INTEGER NOT NULL,  
  PRIMARY KEY (CdnDir)  
);

