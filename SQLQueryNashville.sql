/*

Cleaning data using SQL Queries

*/

------------------------------------------------------------------------------
-- Standardize Date Format. Drop unneccessary timestamp

SELECT saledateconverted, CONVERT(date,saledate)
FROM [dbo].[Housing]

UPDATE [dbo].[Housing]
SET saledate = CONVERT(Date,Saledate)

-- If not updated properly:

ALTER TABLE [dbo].[Housing]
ADD SaleDateConverted Date;

UPDATE [dbo].[Housing]
SET SaleDateConverted = CONVERT(Date,Saledate)

------------------------------------------------------------------------------

-- Populate Address Data Based on same Parcell ID

SELECT *
FROM [dbo].[Housing]
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Self join and populating using ISNULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [dbo].[Housing] AS a
JOIN [dbo].[Housing] AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [dbo].[Housing] AS a
JOIN [dbo].[Housing] AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

------------------------------------------------------------------------------

-- Breaking out Address into individual columns (Address, City, State) using substring and character index

SELECT
SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1) as Address, -- check the postition and delete the comma
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM [dbo].[Housing]

-- Create two new columns and populate with substring
ALTER TABLE [dbo].[Housing]
ADD PropertySplitAddress Nvarchar(255);

UPDATE [dbo].[Housing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE [dbo].[Housing]
ADD PropertySplitCity Nvarchar(255);

UPDATE [dbo].[Housing]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


------------------------------------------------------------------------------

-- Breaking out Owner Address into Address, City, State using parsename

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3), -- replacing comma with periods
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) 
FROM[dbo].[Housing]

-- adding and updating new columns

ALTER TABLE [dbo].[Housing]
ADD OwnerSplitAddress Nvarchar(255);

UPDATE [dbo].[Housing]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE [dbo].[Housing]
ADD OwnerSplitCity Nvarchar(255);

UPDATE [dbo].[Housing]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE [dbo].[Housing]
ADD OwnerSplitState Nvarchar(255);

UPDATE [dbo].[Housing]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

------------------------------------------------------------------------------
-- Change Y and N to Yes and No in Sold as Vacant column using Case Statement

-- Checking how many records of Y and N
SELECT DISTINCT(SoldasVacant), count(soldasvacant)
FROM [dbo].[Housing]
GROUP BY soldasvacant
ORDER BY 2


SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM [dbo].[Housing]

UPDATE [dbo].[Housing]
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END

------------------------------------------------------------------------------
-- Remove duplicates using CTE

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) ROW_NUM

FROM [dbo].[Housing]
)

DELETE
FROM RowNumCTE
WHERE ROW_NUM > 1

------------------------------------------------------------------------------
-- Delete Unused Columns

SELECT *
FROM [dbo].[Housing]

ALTER TABLE [dbo].[Housing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

