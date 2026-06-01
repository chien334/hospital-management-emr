using System;
using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;

namespace RefactorThis.GraphDiff
{
    public interface IUpdateConfiguration<T>
    {
        IUpdateConfiguration<T> OwnedCollection<TElement>(Expression<Func<T, System.Collections.Generic.ICollection<TElement>>> expression) where TElement : class;
        IUpdateConfiguration<T> OwnedCollection<TElement>(Expression<Func<T, System.Collections.Generic.List<TElement>>> expression) where TElement : class;
        IUpdateConfiguration<T> OwnedEntity<TEntity>(Expression<Func<T, TEntity>> expression) where TEntity : class;
    }

    public static class GraphDiffExtensions
    {
        public static T UpdateGraph<T>(this DbContext context, T entity) where T : class
        {
            context.Update(entity);
            return entity;
        }

        public static T UpdateGraph<T>(this DbContext context, T entity, Expression<Func<IUpdateConfiguration<T>, object>> mapping) where T : class
        {
            context.Update(entity);
            return entity;
        }
    }
}
