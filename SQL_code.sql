SELECT *
FROM Nashville_housing_data;

-------------------------------------------------------------------------------------------------------------

    --STANDARDIZE DATE FORMAT--

SELECT 
    SaleDate,
    CONVERT(Date, SaleDate)
FROM Nashville_housing_data;

--Replace SaleDate column values with new converted values

UPDATE Nashville_housing_data
SET SaleDate = CONVERT(Date, SaleDate);

-------------------------------------------------------------------------------------------------------------

    --POPULATE PROPERTY ADDRESS DATA--

--Check where PropertyAddress column is empty

SELECT *
FROM Nashville_housing_data
WHERE PropertyAddress IS NULL;

--Check how ParcelID connects to PropertyAddress (ParcelID is always the same for each property, even when sold more than once)

SELECT *
FROM Nashville_housing_data
ORDER BY ParcelID;

--Check corresponding PropertyAddress values where ParcelIDs repeat but UniqueIDs are different 

SELECT 
    a.ParcelID,
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville_housing_data a
JOIN Nashville_housing_data b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

--Replace NULL values in PropertyAddress with address of same ParcelID

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Nashville_housing_data a
JOIN Nashville_housing_data b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-------------------------------------------------------------------------------------------------------------

    --BREAK ADDRESS INTO INDIVIUDAL COLUMNS (Address, City) and (Address, City, State)--


SELECT PropertyAddress
FROM Nashville_housing_data;

--Split the address and city of PropertyAddress column (replace comma seperators with periods because PARSENAME only works with periods)

SELECT 
    PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2) AS Address,
    PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1) AS City
FROM Nashville_housing_data;

--Create and fill new columns to house these extractions

UPDATE Nashville_housing_data
ADD COLUMN PropertySplitAddress NVARCHAR(255);

ALTER TABLE Nashville_housing_data
SET PropertySplitAddress = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2);

UPDATE Nashville_housing_data
ADD COLUMN PropertySplitCity NVARCHAR(255);

ALTER TABLE Nashville_housing_data
SET PropertySplitCity = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1);


SELECT OwnerAddress
FROM Nashville_housing_data;

--Split the address, city, and state of OwnerAddress column

SELECT 
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM Nashville_housing_data;

--Create and fill new columns to house these extractions

UPDATE Nashville_housing_data
ADD COLUMN OwnerSplitAddress NVARCHAR(255);

ALTER TABLE Nashville_housing_data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE Nashville_housing_data
ADD COLUMN OwnerSplitCity NVARCHAR(255);

ALTER TABLE Nashville_housing_data
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE Nashville_housing_data
ADD COLUMN OwnerSplitState NVARCHAR(255);

ALTER TABLE Nashville_housing_data
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-------------------------------------------------------------------------------------------------------------

    --CHANGE Y AND N TO YES AND NO IN "Sold as Vacant" FIELD--

--Check how many different values exist in SoldAsVacant column (Y, N, Yes, and No) and the count of each

SELECT 
    DISTINCT(SoldAsVacant),
    COUNT(SoldAsVacant)
FROM Nashville_housing_data
GROUP BY SoldAsVacant
ORDER BY 2;

--Set the Y and N values to be Yes and No instead

SELECT
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS NewSoldAsVacant
FROM Nashville_housing_data;

--Change SoldAsVacant column to house these new values of only Yes and No

UPDATE Nashville_housing_data
SET SoldAsVacant = CASE
                    WHEN SoldAsVacant = 'Y' THEN 'Yes'
                    WHEN SoldAsVacant = 'N' THEN 'No'
                    ELSE SoldAsVacant
                END;

-------------------------------------------------------------------------------------------------------------

    --REMOVE DUPLICATES--

--Check how many distinct ParcelID values there are compared to total rows (total rows > distinct parcel IDs = duplicates)

SELECT 
    COUNT(DISTINCT(ParcelID)),
    COUNT(*)
FROM Nashville_housing_data;

--Find and delete rows that are duplicate in ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference

WITH RowNumCTE AS
(
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY 
        	ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
	ORDER BY
		UniqueID) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

-------------------------------------------------------------------------------------------------------------

    --DELETE UNUSED COLUMNS--

ALTER TABLE Nashville_housing_data
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict;
