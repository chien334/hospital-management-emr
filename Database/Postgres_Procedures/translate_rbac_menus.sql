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

-- 5. Dispensary Submenus Translation (First-level and Second-level)
-- First-level submenus under Dispensary (ParentRouteId = 498)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đơn thuốc' WHERE "RouteId" = 155;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bán lẻ' WHERE "RouteId" = 156;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tồn kho' WHERE "RouteId" = 157;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quầy' WHERE "RouteId" = 209;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'In sao lưu' WHERE "RouteId" = 372;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tiêu hao bệnh nhân' WHERE "RouteId" = 669;

-- Second-level submenus under Sale (ParentRouteId = 156)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bán lẻ mới' WHERE "RouteId" = 312;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách hóa đơn' WHERE "RouteId" = 313;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Khách trả lại' WHERE "RouteId" = 314;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách trả lại' WHERE "RouteId" = 315;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hóa đơn tạm tính' WHERE "RouteId" = 316;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quyết toán' WHERE "RouteId" = 317;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Trả lại tạm tính' WHERE "RouteId" = 374;

-- Second-level submenus under Stock (ParentRouteId = 157)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Chi tiết tồn kho' WHERE "RouteId" = 322;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hàng hỏng/vỡ' WHERE "RouteId" = 324;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Chuyển kho' WHERE "RouteId" = 506;

-- Second-level submenus under Duplicate Prints (ParentRouteId = 372)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Trả lại hóa đơn' WHERE "RouteId" = 373;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quyết toán' WHERE "RouteId" = 382;

-- Second-level submenus under Reports (ParentRouteId = 499)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Doanh thu người dùng' WHERE "RouteId" = 541;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Doanh số thuốc gây nghiện hàng ngày' WHERE "RouteId" = 542;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tổng hợp thu tiền mặt' WHERE "RouteId" = 545;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo doanh số hàng ngày' WHERE "RouteId" = 547;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo tổng hợp quyết toán' WHERE "RouteId" = 614;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo theo hình thức thanh toán' WHERE "RouteId" = 637;

-- Second-level submenus under Patient Consumption (ParentRouteId = 669)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách tiêu hao' WHERE "RouteId" = 666;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách tiêu hao trả lại' WHERE "RouteId" = 670;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách tiêu hao đã quyết toán' WHERE "RouteId" = 671;

-- 6. Core EMR Modules Submenus Translation
-- Appointment Submenus (ParentRouteId = 30)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đăng ký khám' WHERE "RouteId" = 31;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách lịch hẹn' WHERE "RouteId" = 32;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đặt lịch hẹn' WHERE "RouteId" = 33;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách lượt khám' WHERE "RouteId" = 34;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đăng ký khám mới' WHERE "RouteId" = 35;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'In nhãn dán' WHERE "RouteId" = 36;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đặt hẹn trực tuyến' WHERE "RouteId" = 620;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Yêu cầu thanh toán SSF' WHERE "RouteId" = 647;

-- Billing Submenus (ParentRouteId = 37)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tìm kiếm bệnh nhân' WHERE "RouteId" = 39;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Giao dịch thanh toán' WHERE "RouteId" = 40;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thanh toán tạm tính' WHERE "RouteId" = 41;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quyết toán tạm tính' WHERE "RouteId" = 42;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Biên lai thanh toán' WHERE "RouteId" = 43;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Chỉ định dịch vụ' WHERE "RouteId" = 44;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đặt cọc thanh toán' WHERE "RouteId" = 45;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hủy hóa đơn' WHERE "RouteId" = 46;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Trả lại hóa đơn' WHERE "RouteId" = 47;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Kích hoạt quầy' WHERE "RouteId" = 48;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'In bản sao' WHERE "RouteId" = 49;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Sửa bác sĩ chỉ định' WHERE "RouteId" = 50;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quyết toán' WHERE "RouteId" = 175;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thanh toán nội trú' WHERE "RouteId" = 256;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bàn giao ca' WHERE "RouteId" = 275;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tạm tính bảo hiểm' WHERE "RouteId" = 277;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bảo hiểm' WHERE "RouteId" = 279;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Quét thẻ y tế' WHERE "RouteId" = 341;

-- Laboratory Submenus (ParentRouteId = 51)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Chỉ định lấy mẫu' WHERE "RouteId" = 53;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Lấy mẫu xét nghiệm' WHERE "RouteId" = 54;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhập kết quả' WHERE "RouteId" = 55;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo chưa hoàn thành' WHERE "RouteId" = 56;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Xem báo cáo kết quả' WHERE "RouteId" = 57;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhập nhanh kết quả' WHERE "RouteId" = 58;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách mẫu bệnh án' WHERE "RouteId" = 59;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo cuối cùng' WHERE "RouteId" = 142;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thanh toán buồng bệnh' WHERE "RouteId" = 222;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tìm kiếm tổng thể / Mã vạch' WHERE "RouteId" = 223;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Xét nghiệm bên ngoài' WHERE "RouteId" = 267;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Trả kết quả xét nghiệm' WHERE "RouteId" = 288;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thông báo' WHERE "RouteId" = 543;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hệ thống LIS' WHERE "RouteId" = 582;

-- Radiology Submenus (ParentRouteId = 62)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách yêu cầu' WHERE "RouteId" = 63;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách báo cáo' WHERE "RouteId" = 64;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Xem kết quả CĐHA' WHERE "RouteId" = 66;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thanh toán buồng bệnh' WHERE "RouteId" = 250;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Sửa bác sĩ' WHERE "RouteId" = 424;

-- ADT / Admission Submenus (ParentRouteId = 67)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhập viện mới' WHERE "RouteId" = 68;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tìm kiếm bệnh nhân' WHERE "RouteId" = 69;

-- Helpdesk Submenus (ParentRouteId = 106)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thông tin nhân viên' WHERE "RouteId" = 107;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thông tin buồng giường' WHERE "RouteId" = 108;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thông tin khoa/phòng' WHERE "RouteId" = 109;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thông tin hàng đợi' WHERE "RouteId" = 603;

-- Inventory Submenus (ParentRouteId = 110)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Yêu cầu nội bộ' WHERE "RouteId" = 112;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tồn kho' WHERE "RouteId" = 165;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Trả hàng nhà cung cấp' WHERE "RouteId" = 468;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tài trợ/Hiến tặng' WHERE "RouteId" = 623;

-- Procurement Submenus (ParentRouteId = 118)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tạo đơn đặt hàng' WHERE "RouteId" = 120;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh mục nhận hàng' WHERE "RouteId" = 121;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thông báo hàng về' WHERE "RouteId" = 162;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Chi tiết nhận hàng' WHERE "RouteId" = 163;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Chi tiết đơn đặt hàng' WHERE "RouteId" = 164;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo giá' WHERE "RouteId" = 467;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách nhà cung cấp' WHERE "RouteId" = 469;

-- Nursing Submenus (ParentRouteId = 147)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Yêu cầu điều dưỡng' WHERE "RouteId" = 148;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách yêu cầu' WHERE "RouteId" = 149;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân ngoại trú' WHERE "RouteId" = 150;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân nội trú' WHERE "RouteId" = 151;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Khoa thận' WHERE "RouteId" = 240;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách lĩnh đồ' WHERE "RouteId" = 247;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tổng quan bệnh nhân' WHERE "RouteId" = 411;

-- Pharmacy Submenus (ParentRouteId = 152)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Đơn thuốc' WHERE "RouteId" = 153;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Báo cáo' WHERE "RouteId" = 158;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Cài đặt' WHERE "RouteId" = 159;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Lĩnh thuốc/Vật tư' WHERE "RouteId" = 224;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Yêu cầu kho phụ' WHERE "RouteId" = 234;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Kho thuốc' WHERE "RouteId" = 246;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhà cung cấp' WHERE "RouteId" = 274;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Sổ cái nhà cung cấp' WHERE "RouteId" = 561;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Yêu cầu/Cấp phát kho phụ' WHERE "RouteId" = 684;

-- Emergency Submenus (ParentRouteId = 235)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân mới' WHERE "RouteId" = 252;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân đã phân loại' WHERE "RouteId" = 253;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Bệnh nhân đã xử trí xong' WHERE "RouteId" = 254;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Thông tin buồng giường' WHERE "RouteId" = 255;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Tổng quan bệnh nhân' WHERE "RouteId" = 481;

-- Medical Records Submenus (ParentRouteId = 354)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hồ sơ nội trú' WHERE "RouteId" = 355;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách sinh' WHERE "RouteId" = 357;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Danh sách tử vong' WHERE "RouteId" = 358;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hồ sơ ngoại trú' WHERE "RouteId" = 565;
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Hồ sơ cấp cứu' WHERE "RouteId" = 645;

-- Verification Submenus (ParentRouteId = 400)
UPDATE "RBAC_RouteConfig" SET "DisplayName_vi" = 'Nhà thuốc' WHERE "RouteId" = 689;


