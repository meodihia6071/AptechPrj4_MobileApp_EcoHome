USE [ApartmentManagement];
GO

/* =========================================================
   1. THÔNG BÁO KHI TRẠNG THÁI SỰ CỐ THAY ĐỔI
   ========================================================= */
CREATE OR ALTER TRIGGER dbo.TR_Incidents_CreateNotification
ON dbo.Incidents
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Notifications
    (
        NotificationId,
        Title,
        Description,
        ReceiveEnum,
        ResidentId,
        PaymentId,
        Status,
        CreatedDate,
        ModifiedDate,
        IsDeleted
    )
    SELECT
        NEWID(),
        CASE i.Status
            WHEN 0 THEN N'Báo cáo sự cố đã được tiếp nhận'
            WHEN 1 THEN N'Báo cáo sự cố đang được xử lý'
            WHEN 2 THEN N'Sự cố đã có hướng khắc phục'
            WHEN 3 THEN N'Báo cáo sự cố đã hoàn thành'
            WHEN 4 THEN N'Báo cáo sự cố đã được mở lại'
            WHEN 5 THEN N'Báo cáo sự cố đã được thu hồi'
            ELSE N'Trạng thái báo cáo sự cố đã thay đổi'
        END,
        CONCAT(
            N'Báo cáo ',
            N'#INC-',
            UPPER(LEFT(REPLACE(CONVERT(NVARCHAR(36), i.IncidentId), N'-', N''), 8)),
            N' đã chuyển sang trạng thái: ',
            CASE i.Status
                WHEN 0 THEN N'Mới'
                WHEN 1 THEN N'Đang xử lý'
                WHEN 2 THEN N'Đã khắc phục'
                WHEN 3 THEN N'Đã hoàn thành'
                WHEN 4 THEN N'Mở lại'
                WHEN 5 THEN N'Đã thu hồi'
                ELSE N'Không xác định'
            END,
            N'.'
        ),
        1,                  -- Resident
        i.ReportedBy,
        NULL,
        1,                  -- Unread
        GETDATE(),
        GETDATE(),
        0
    FROM inserted i
    INNER JOIN deleted d
        ON d.IncidentId = i.IncidentId
    WHERE i.Status <> d.Status;
END;
GO

/* =========================================================
   2. THÔNG BÁO KHI CÓ KHOẢN THANH TOÁN MỚI
      HOẶC TRẠNG THÁI THANH TOÁN THAY ĐỔI
   ========================================================= */
CREATE OR ALTER TRIGGER dbo.TR_Payments_CreateNotification
ON dbo.Payments
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Notifications
    (
        NotificationId,
        Title,
        Description,
        ReceiveEnum,
        ResidentId,
        PaymentId,
        Status,
        CreatedDate,
        ModifiedDate,
        IsDeleted
    )
    SELECT
        NEWID(),
        CASE
            WHEN d.PaymentId IS NULL
                THEN N'Bạn có khoản thanh toán mới'
            WHEN i.PaymentStatus = 0
                THEN N'Khoản thanh toán đang chờ'
            WHEN i.PaymentStatus = 1
                THEN N'Thanh toán đã được xác nhận'
            WHEN i.PaymentStatus = 2
                THEN N'Khoản thanh toán bị ghi nhận muộn'
            WHEN i.PaymentStatus = 3
                THEN N'Khoản thanh toán đã quá hạn'
            ELSE N'Trạng thái thanh toán đã thay đổi'
        END,
        CONCAT(
            i.Title,
            N'. Số tiền: ',
            FORMAT(i.Amount, N'N0', N'vi-VN'),
            N'đ. Hạn thanh toán: ',
            FORMAT(i.PaymentDeadline, N'dd/MM/yyyy'),
            N'.'
        ),
        1,                  -- Resident
        i.ResidentId,
        i.PaymentId,
        1,                  -- Unread
        GETDATE(),
        GETDATE(),
        0
    FROM inserted i
    LEFT JOIN deleted d
        ON d.PaymentId = i.PaymentId
    WHERE
        d.PaymentId IS NULL
        OR i.PaymentStatus <> d.PaymentStatus;
END;
GO

/* =========================================================
   3. THÔNG BÁO MẪU TỪ BAN QUẢN LÝ CHO TOÀN BỘ CƯ DÂN
   Chạy phần INSERT này mỗi khi ban quản lý cần gửi thông báo.
   ========================================================= */
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Notifications
    WHERE Title = N'Thông báo bảo trì thang máy'
      AND IsDeleted = 0
)
BEGIN
    INSERT INTO dbo.Notifications
    (
        NotificationId,
        Title,
        Description,
        ReceiveEnum,
        ResidentId,
        PaymentId,
        Status,
        CreatedDate,
        ModifiedDate,
        IsDeleted
    )
    VALUES
    (
        NEWID(),
        N'Thông báo bảo trì thang máy',
        N'Thang máy khu A sẽ được bảo trì từ 09:00 đến 11:00 ngày mai. Cư dân vui lòng sử dụng thang máy khu B.',
        1,          -- Resident
        NULL,       -- NULL nghĩa là gửi cho toàn bộ cư dân
        NULL,
        1,          -- Unread
        GETDATE(),
        GETDATE(),
        0
    );
END;
GO

/* =========================================================
   4. KIỂM TRA THÔNG BÁO
   ========================================================= */
SELECT
    NotificationId,
    Title,
    Description,
    ReceiveEnum,
    ResidentId,
    PaymentId,
    Status,
    CreatedDate,
    IsDeleted
FROM dbo.Notifications
ORDER BY CreatedDate DESC;
GO
