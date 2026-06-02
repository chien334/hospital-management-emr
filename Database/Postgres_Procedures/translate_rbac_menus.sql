-- 1. Add DisplayName_vi column to RBAC_RouteConfig if it doesn't already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'RBAC_RouteConfig' AND column_name = 'DisplayName_vi'
    ) THEN
        ALTER TABLE "RBAC_RouteConfig" ADD COLUMN "DisplayName_vi" character varying(100);
    END IF;
END $$;

-- 2. Default all DisplayName_vi values to English DisplayName
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = "DisplayName";

-- 3. Update top-level navigation menus to Vietnamese
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bác sĩ' WHERE "DisplayName" = 'Doctor';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân' WHERE "DisplayName" = 'Patient';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Lịch hẹn' WHERE "DisplayName" = 'Appointment';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thanh toán' WHERE "DisplayName" = 'Billing';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Xét nghiệm' WHERE "DisplayName" = 'Laboratory';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Chẩn đoán hình ảnh' WHERE "DisplayName" = 'Radiology';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhập viện (ADT)' WHERE "DisplayName" = 'ADT';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Cài đặt' WHERE "DisplayName" = 'Settings';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo' WHERE "DisplayName" = 'Reports';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bàn trợ giúp' WHERE "DisplayName" = 'Helpdesk';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Kho hàng' WHERE "DisplayName" = 'Inventory';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Mua sắm' WHERE "DisplayName" = 'Procurement';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Kế toán' WHERE "DisplayName" = 'Accounting';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quản trị hệ thống' WHERE "DisplayName" = 'System Admin';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Điều dưỡng' WHERE "DisplayName" = 'Nursing';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhà thuốc' WHERE "DisplayName" = 'Pharmacy';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Kho phụ' WHERE "DisplayName" = 'Sub Store';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Cấp cứu' WHERE "DisplayName" = 'Emergency';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Khuyến khích' WHERE "DisplayName" = 'Incentive';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hồ sơ y tế' WHERE "DisplayName" = 'Medical Records';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Xác minh' WHERE "DisplayName" = 'Verification';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quầy thuốc' WHERE "DisplayName" = 'Dispensary';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bảo hiểm NHIF' WHERE "DisplayName" = 'NHIF';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Dịch vụ xã hội' WHERE "DisplayName" = 'Social Service';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Phòng mổ' WHERE "DisplayName" = 'OperationTheatre';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Sản khoa' WHERE "DisplayName" = 'Maternity';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tài sản cố định' WHERE "DisplayName" = 'Fixed Assets';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'CSSD (Tiệt trùng)' WHERE "DisplayName" = 'CSSD';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tiêm chủng' WHERE "DisplayName" = 'Vaccination';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quản lý xếp hàng' WHERE "DisplayName" = 'Queue Mngmt';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo động' WHERE "DisplayName" = 'DynamicReport';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Yêu cầu thanh toán' WHERE "DisplayName" = 'Claim Mgmt';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tiện ích' WHERE "DisplayName" = 'Utilities';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tiếp thị & Giới thiệu' WHERE "DisplayName" = 'MktReferral';

-- 4. Update key second-level/common menus
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách bệnh nhân EMR' WHERE "DisplayName" = 'EMR Patient List';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tạo lịch hẹn' WHERE "DisplayName" = 'New Visit';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân nội trú' WHERE "DisplayName" = 'Admitted Patients';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân đã xuất viện' WHERE "DisplayName" = 'Discharged Patients';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đăng ký giường' WHERE "DisplayName" = 'Bed Reservation';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tóm tắt xuất viện' WHERE "DisplayName" = 'Discharge Summary';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bán hàng' WHERE "DisplayName" = 'Sales';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhận hàng' WHERE "DisplayName" = 'Goods Receipt';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Yêu cầu mua hàng' WHERE "DisplayName" = 'Purchase Request';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đơn đặt hàng' WHERE "DisplayName" = 'Purchase Order';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Trả hàng nhà cung cấp' WHERE "DisplayName" = 'Return to Supplier';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách Voucher' WHERE "DisplayName" = 'Vouchers';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhập Voucher' WHERE "DisplayName" = 'Voucher Entry';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Sổ cái' WHERE "DisplayName" = 'Ledgers';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Người dùng' WHERE "DisplayName" = 'Manage User';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Vai trò' WHERE "DisplayName" = 'Manage Role';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quyền hạn' WHERE "DisplayName" = 'Manage User';
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhân viên' WHERE "DisplayName" = 'Manage Employee';
