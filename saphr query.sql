--HR SAP Project

--query for github
-- Payroll Calculation for April and May
--Monthly leave-based deduction
WITH leave_summary AS (
    SELECT 
        e.pernr,
        MONTH(CAST(l.end_Date AS date)) AS month_num,
        DATENAME(month, CAST(l.end_Date AS date)) AS month_name,
        SUM(
            CASE 
                WHEN l.unit = 'D' THEN ISNULL(l.duration, 0) * 1000
                WHEN l.unit = 'H' THEN 500
                ELSE 0
            END
        ) AS total_leave_deduction
    FROM SAP_EMP e
    LEFT JOIN SAP_LEAVE_NEW l ON e.PERNR = l.PERNR
    WHERE l.end_date IS NOT NULL
    GROUP BY e.pernr, MONTH(CAST(l.end_Date AS date)), DATENAME(month, CAST(l.end_Date AS date))
),

-- Deduction for May (without joining with leave)
deduction_may AS (
    SELECT 
        pernr,
        SUM(CAST(amount AS int)) AS total_deduction_may
    FROM SAP_DEDUCTION
    WHERE pay_date = '2025-05-31'
    GROUP BY pernr
),

-- Deduction for April
deduction_april AS (
    SELECT 
        pernr,
        SUM(CAST(amount AS int)) AS total_deduction_april
    FROM SAP_DEDUCTION
    WHERE pay_date = '2025-04-30'
    GROUP BY pernr
),

-- Base payroll with salary and deductions
payroll AS (
    SELECT 
        s.pernr AS emp_id,
        e.FIRST_NAME + ' ' + e.LAST_NAME AS employee_name,
        s.amount AS salary_without_reduction,
        ISNULL(dm.total_deduction_may, 0) AS deduction_may,
        ISNULL(da.total_deduction_april, 0) AS deduction_april,
        s.amount - ISNULL(dm.total_deduction_may, 0) AS payroll_may,
        s.amount - ISNULL(da.total_deduction_april, 0) AS payroll_april
    FROM SAP_SAL s
    JOIN SAP_EMP e ON e.PERNR = s.PERNR
    LEFT JOIN deduction_may dm ON dm.pernr = s.pernr
    LEFT JOIN deduction_april da ON da.pernr = s.pernr
),

-- Adding leave deductions for April and May
leave_calci AS (
    SELECT 
        p.*,
        ISNULL(ls_apr.total_leave_deduction, 0) AS leave_sal_april,
        ISNULL(ls_may.total_leave_deduction, 0) AS leave_sal_may
    FROM payroll p
    LEFT JOIN leave_summary ls_apr 
        ON p.emp_id = ls_apr.pernr AND ls_apr.month_num = 4
    LEFT JOIN leave_summary ls_may 
        ON p.emp_id = ls_may.pernr AND ls_may.month_num = 5
),

-- Final calculation
Final_Ans AS (
    SELECT 
        emp_id,
        employee_name,
        salary_without_reduction,
        deduction_may,
        deduction_april,
        leave_sal_april,
        leave_sal_may,
        payroll_april - leave_sal_april AS final_sal_april,
        payroll_may - leave_sal_may AS final_sal_may
    FROM leave_calci
)

-- Final result output
SELECT 
    emp_id,
    employee_name,
    salary_without_reduction,
    deduction_may,
    deduction_april,
    leave_sal_may,
    leave_sal_april,
    final_sal_may,
    final_sal_april
FROM Final_Ans
ORDER BY emp_id;






