/***********************
**Cleaning data in SQL**
***********************/

SELECT *
FROM [Housing-data-for-cleaning-Project].dbo.HousingData

---------------------------
--Standardise date format--
---------------------------

SELECT SaleDate, CONVERT(date, SaleDate)
FROM [Housing-data-for-cleaning-Project].dbo.HousingData

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET SaleDate = CONVERT(date, SaleDate)

ALTER TABLE [Housing-data-for-cleaning-Project].dbo.HousingData
ADD SaleDateConverted Date

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET SaleDateConverted = CONVERT(date,SaleDate)

----------------------------------
--Populate property address data--
----------------------------------

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Housing-data-for-cleaning-Project].dbo.HousingData a
JOIN [Housing-data-for-cleaning-Project].dbo.HousingData b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Housing-data-for-cleaning-Project].dbo.HousingData a
JOIN [Housing-data-for-cleaning-Project].dbo.HousingData b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-----------------------------------------------------------------------
--Breaking out address into individual columns (Address, city, state)--
-----------------------------------------------------------------------
--Address and city--
--------------------

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM [Housing-data-for-cleaning-Project].dbo.HousingData

ALTER TABLE [Housing-data-for-cleaning-Project].dbo.HousingData
ADD PropertySplitAddress Nvarchar(255);

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE [Housing-data-for-cleaning-Project].dbo.HousingData
ADD PropertySplitCity Nvarchar(255);

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

----------------------------
--Address, city, and state--
----------------------------

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM [Housing-data-for-cleaning-Project].dbo.HousingData

ALTER TABLE [Housing-data-for-cleaning-Project].dbo.HousingData
ADD OwnerSplitAddress Nvarchar(255);

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE [Housing-data-for-cleaning-Project].dbo.HousingData
ADD OwnerSplitCity Nvarchar(255);

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE [Housing-data-for-cleaning-Project].dbo.HousingData
ADD OwnerSplitState Nvarchar(255);

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

---------------------------------------------------------
--Change Y and N to Yes and No in "SoldAsVacant" column--
---------------------------------------------------------

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [Housing-data-for-cleaning-Project].dbo.HousingData
GROUP BY SoldAsVacant
ORDER BY 2 DESC

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM [Housing-data-for-cleaning-Project].dbo.HousingData

UPDATE [Housing-data-for-cleaning-Project].dbo.HousingData
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

---------------------
--Remove duplicates--
---------------------

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDateConverted,
				 LegalReference
	ORDER BY UniqueID
	) row_num
FROM [Housing-data-for-cleaning-Project].dbo.HousingData
)
--SELECT *
--FROM RowNumCTE
--WHERE row_num > 1
DELETE
FROM RowNumCTE
WHERE row_num > 1

-------------------------
--Delete unused columns--
-------------------------

ALTER TABLE [Housing-data-for-cleaning-Project].dbo.HousingData
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress